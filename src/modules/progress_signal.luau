if game then
	local Signal = require(script.Parent.Parent.roblox_packages.signal)

	type Signal<T...> = Signal.Signal<T...>

	local progress_signal: Signal<string, number?> = Signal.new()

	return progress_signal
else
	-- Not Roblox.
	local function nothing()
	end

	local signal: any = {
		FireSync = nothing
	}
	
	return signal
end
