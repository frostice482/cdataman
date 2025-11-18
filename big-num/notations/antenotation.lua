local lovely = require("lovely")
local nativefs = require("nativefs")
Notation = nativefs.load(Talisman.mod_path.."/big-num/notations/notation.lua")()
AnteNotation = {}
AnteNotation.__index = AnteNotation
AnteNotation.E_SWITCH_POINT = 1000
AnteNotation.__tostring = function ()
    return "AnteNotation"
end
setmetatable(AnteNotation, Notation)

function AnteNotation:new()
    return setmetatable({}, AnteNotation)
end

function AnteNotation:format(n, places)
    local str = ""
    local size = 0
    local found = false
    local i = 1
    while not found do
        size = get_blind_amount(i)
        i = i + 1
        found = size >= n

        found = found or (i > 100)
    end

    str = Notation.format_mantissa(to_number(n / size), 2) .. "A" .. i 


    return str
end

return AnteNotation