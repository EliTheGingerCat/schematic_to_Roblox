local progress_signal = require("./progress_signal")
local zzlib = require("./zzlib")

local function decode(data: buffer): buffer
	progress_signal:FireSync("unzip")
	local data_string = buffer.tostring(data)
	local result_string = zzlib.gunzip(data_string)
	local result_buffer = buffer.fromstring(result_string)
	return result_buffer
end

return {
	decode = decode,
}
