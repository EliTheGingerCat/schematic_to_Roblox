local process = require("@lune/process")

process.exec("rojo", {"build", "--plugin", "schematic_to_Roblox.rbxm", "--watch"})
