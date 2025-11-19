local lovely = require("lovely")
local nativefs = require("nativefs")
Notation = nativefs.load(Talisman.mod_path.."/big-num/notations/notation.lua")()

BaseLetterNotation = {}
BaseLetterNotation.__index = BaseLetterNotation
BaseLetterNotation.__tostring = function (notation)
    return "BaseLetterNotation {"..(notation.letters or "").."}"
end
setmetatable(BaseLetterNotation, Notation)

function BaseLetterNotation:new(opt)
    opt = opt or {}
    return setmetatable({
        letters = opt.letters,
        dynamic = opt.dynamic,
        reversed = opt.reversed
    }, BaseLetterNotation)
end

function BaseLetterNotation:get_letters(n)
    local order = math.floor(n:log10():floor() / 3)
    local result = ""
    while order > 0 do
        local letter_index = 1 + order % #self.letters
        result = self.letters:sub(letter_index, letter_index) .. result
        order = math.floor(order / #self.letters)
    end
    return result
end

function BaseLetterNotation:get_number(n, places)
    -- local num = n.m * 10 ^ (n.e % 3)
    -- mantissa E (exponent mod 3)
    local mantissa = n:div(10 ^ n:log10():floor())
    local exponent = n:log10():floor()

    local num = mantissa * 10 ^ (exponent % 3)
    num = num:to_number()

    return Notation.format_mantissa(num, places)
end

function BaseLetterNotation:get_prefix(n)
    if self.reversed then return self:get_letters(n) else return "" end
end

function BaseLetterNotation:get_suffix(n)
    if not self.reversed then return self:get_letters(n) else return "" end
end

return BaseLetterNotation