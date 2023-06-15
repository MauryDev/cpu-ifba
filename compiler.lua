local Matel = require("matel")
local RegisterFlag = Matel.RegisterFlag
local file = Matel.new("output.txt")

if file ~= nil then
    file.movi(RegisterFlag.R0,23)
    file.movi(RegisterFlag.R1,23)
    file.add(RegisterFlag.R0,RegisterFlag.R1)
    file.storeai(RegisterFlag.R0,2)
end

