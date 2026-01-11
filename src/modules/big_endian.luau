local function twos_complement(unsigned: number, length: number): number
	if unsigned > 2^(length * 8 - 1) - 1 then
		return unsigned - 2^(length * 8)
	else
		return unsigned
	end
end

local function u2(data: buffer, offset: number): number
	return (
		  bit32.lshift(buffer.readu8(data, offset),     8)
		+              buffer.readu8(data, offset + 1)
	)
end

local function u3(data: buffer, offset: number): number
	return (
		  bit32.lshift(buffer.readu8(data, offset),     16)
		+ bit32.lshift(buffer.readu8(data, offset + 1), 8)
		+              buffer.readu8(data, offset + 2)
	)
end

local function u4(data: buffer, offset: number): number
	return (
		  bit32.lshift(buffer.readu8(data, offset),     24)
		+ bit32.lshift(buffer.readu8(data, offset + 1), 16)
		+ bit32.lshift(buffer.readu8(data, offset + 2), 8)
		+              buffer.readu8(data, offset + 3)
	)
end

local function u5(data: buffer, offset: number): number
	return (
		  bit32.lshift(buffer.readu8(data, offset),     32)
		+ bit32.lshift(buffer.readu8(data, offset + 1), 24)
		+ bit32.lshift(buffer.readu8(data, offset + 2), 16)
		+ bit32.lshift(buffer.readu8(data, offset + 3), 8)
		+              buffer.readu8(data, offset + 4)
	)
end

local function u6(data: buffer, offset: number): number
	return (
		  bit32.lshift(buffer.readu8(data, offset),     40)
		+ bit32.lshift(buffer.readu8(data, offset + 1), 32)
		+ bit32.lshift(buffer.readu8(data, offset + 2), 24)
		+ bit32.lshift(buffer.readu8(data, offset + 3), 16)
		+ bit32.lshift(buffer.readu8(data, offset + 4), 8)
		+              buffer.readu8(data, offset + 5)
	)
end

local function u7(data: buffer, offset: number): number
	return (
		  bit32.lshift(buffer.readu8(data, offset),     48)
		+ bit32.lshift(buffer.readu8(data, offset + 1), 40)
		+ bit32.lshift(buffer.readu8(data, offset + 2), 32)
		+ bit32.lshift(buffer.readu8(data, offset + 3), 24)
		+ bit32.lshift(buffer.readu8(data, offset + 4), 16)
		+ bit32.lshift(buffer.readu8(data, offset + 5), 8)
		+              buffer.readu8(data, offset + 6)
	)
end

local function u8(data: buffer, offset: number): number
	return (
		  bit32.lshift(buffer.readu8(data, offset),     56)
		+ bit32.lshift(buffer.readu8(data, offset + 1), 48)
		+ bit32.lshift(buffer.readu8(data, offset + 2), 40)
		+ bit32.lshift(buffer.readu8(data, offset + 3), 32)
		+ bit32.lshift(buffer.readu8(data, offset + 4), 24)
		+ bit32.lshift(buffer.readu8(data, offset + 5), 16)
		+ bit32.lshift(buffer.readu8(data, offset + 6), 8)
		+              buffer.readu8(data, offset + 7)
	)
end

local function i2(data: buffer, offset: number): number
	return twos_complement(u2(data, offset), 2)
end

local function i3(data: buffer, offset: number): number
	return twos_complement(u3(data, offset), 3)
end

local function i4(data: buffer, offset: number): number
	return twos_complement(u4(data, offset), 4)
end

local function i5(data: buffer, offset: number): number
	return twos_complement(u5(data, offset), 5)
end

local function i6(data: buffer, offset: number): number
	return twos_complement(u6(data, offset), 6)
end

local function i7(data: buffer, offset: number): number
	return twos_complement(u7(data, offset), 7)
end

local function i8(data: buffer, offset: number): number
	return twos_complement(u8(data, offset), 8)
end

local big_endian = {
	u2 = u2,
	u3 = u3,
	u4 = u4,
	u5 = u5,
	u6 = u6,
	u7 = u7,
	u8 = u8,
	i2 = i2,
	i3 = i3,
	i4 = i4,
	i5 = i5,
	i6 = i6,
	i7 = i7,
	i8 = i8,
}

return big_endian
