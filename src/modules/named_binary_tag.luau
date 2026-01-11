local big_endian = require("./big_endian")
local progress_signal = require("./progress_signal")

local be_i2 = big_endian.i2
local be_i4 = big_endian.i4
local be_i8 = big_endian.i8
local be_u4 = big_endian.u4

type payload = number | string | {number} | {payload} | {[string]: payload}

type stack_compound = {
	kind: "compound",
	payload: {
		[string]: payload,
	},
}

type stack_list = {
	kind: "list",
	item_type: number,
	size: number,
	payload: {payload},
}

type stack_item = stack_compound | stack_list

type string_data = {
	content: string,
	length: number,
}
local function read_string(data: buffer, offset: number): string_data
	local length = be_i2(data, offset)
	return {
		content = buffer.readstring(data, offset + 2, length),
		length = length,
	}
end

local function decode(data: buffer): {name: string, payload: payload}
	progress_signal:FireSync("nbt")
	local offset = 0
	local buffer_length = buffer.len(data)
	local list_is_active = false
	local list_type = 0
	local stack: {stack_item} = {
		{
			kind = "compound",
			payload = {},
		}
	}

	while true do
		if offset >= buffer_length then
			break
		end

		local tag_type: number
		if list_is_active then
			tag_type = list_type
		else
			tag_type = buffer.readu8(data, offset)
			offset += 1
		end

		if tag_type == 0 then
			-- TAG_End
			local top = assert(table.remove(stack), "Stack is empty.")
			assert(top.kind == "compound", "Top item is not a compound even though TAG_End wants to terminate a compound.")
			local top_next = stack[#stack]
			if top_next.kind == "list" then
				list_is_active = true
				list_type = top_next.item_type
			end
			continue
		end

		local name: string
		if list_is_active == false then
			local string_data = read_string(data, offset)
			name = string_data.content
			offset += string_data.length + 2
		end

		local payload: any
		local do_add_compound = false
		local do_add_list = false
		local list_size: number
		if tag_type == 1 then
			-- TAG_Byte
			payload = buffer.readi8(data, offset)
			offset += 1
		elseif tag_type == 2 then
			-- TAG_Short
			payload = be_i2(data, offset)
			offset += 2
		elseif tag_type == 3 then
			-- TAG_Int
			payload = be_i4(data, offset)
			offset += 4
		elseif tag_type == 4 then
			-- TAG_Long
			payload = be_i8(data, offset)
			offset += 8
		elseif tag_type == 5 then
			-- TAG_Float
			payload = buffer.readf32(data, offset)
			offset += 4
		elseif tag_type == 6 then
			-- TAG_Double
			payload = buffer.readf64(data, offset)
			offset += 8
		elseif tag_type == 7 then
			-- TAG_Byte_Array
			local length = be_i4(data, offset)
			offset += 4
			payload = table.create(length)
			for index = 1, length do
				payload[index] = buffer.readi8(data, offset)
				offset += 1
			end
		elseif tag_type == 8 then
			-- TAG_String
			local string_data = read_string(data, offset)
			payload = string_data.content
			offset += string_data.length + 2
		elseif tag_type == 9 then
			-- TAG_List
			payload = {}
			list_type = buffer.readu8(data, offset)
			list_size = be_u4(data, offset + 1)
			-- Lists only get checked for deletion when new elements are added. New elements will never be added for empty lists, meaning they will linger in the stack.
			do_add_list = list_size ~= 0
			offset += 5
		elseif tag_type == 10 then
			-- TAG_Compound
			payload = {}
			do_add_compound = true
		elseif tag_type == 11 then
			-- TAG_Int_Array
			local length = be_i4(data, offset)
			offset += 4
			payload = table.create(length)
			for index = 1, length do
				payload[index] = be_i4(data, offset)
				offset += 4
			end
		elseif tag_type == 12 then
			-- TAG_Long_Array
			local length = be_i4(data, offset)
			offset += 4
			payload = table.create(length)
			for index = 1, length do
				payload[index] = be_i8(data, offset)
				offset += 8
			end
		else
			error("Unknown tag type: " .. tag_type)
		end

		local top = stack[#stack]
		if top.kind == "compound" then
			top.payload[name] = payload
		elseif top.kind == "list" then
			local new_index = #top.payload + 1
			top.payload[new_index] = payload
			if new_index == top.size then
				table.remove(stack)
			end
		else
			error(`Item in stack has invalid kind "{top.kind}".`)
		end

		if do_add_list then
			local list: stack_list = {
				kind = "list",
				item_type = list_type,
				size = list_size,
				payload = payload,
			}
			table.insert(stack, list)
			list_is_active = true
		elseif do_add_compound then
			local compound: stack_compound = {
				name = name,
				kind = "compound",
				payload = payload,
			}
			table.insert(stack, compound)
			list_is_active = false
		end
	end

	assert(#stack == 1, "Some compounds/lists were not terminated.")
	local root_payload = stack[1].payload :: {[string]: payload}
	local name = next(root_payload)
	assert(type(name) == "string", "Name of first item is not a string.")
	return {
		name = name,
		payload = root_payload[name],
	}
end

return {
	decode = decode,
}
