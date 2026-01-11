local Signal = require(script.Parent.Parent.roblox_packages.signal)

type Signal<T...> = Signal.Signal<T...>

local progress_signal: Signal<string, number?> = Signal.new()

return progress_signal
