local lovely = require("lovely")
local nativefs = require("nativefs")
Notation = nativefs.load(Talisman.mod_path.."/big-num/notations/notation.lua")()
LetterNotation = {}
LetterNotation.__index = LetterNotation
LetterNotation.__tostring = function ()
    return "LetterNotation"
end
setmetatable(LetterNotation, Notation)

function LetterNotation:new()
    return setmetatable({}, LetterNotation)
end

local letters = "abcdefghijklmnopqrstuvwxyz"

function LetterNotation:format(n, places)
    return "haha,"
end

return LetterNotation