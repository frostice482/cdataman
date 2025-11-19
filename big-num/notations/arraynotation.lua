local Notation = require("big-num.notations.notation")

local ArrayNotation = {}
ArrayNotation.__index = ArrayNotation
ArrayNotation.E_SWITCH_POINT = 10000
ArrayNotation.__tostring = function ()
    return "ArrayNotation"
end
setmetatable(ArrayNotation, Notation)

function ArrayNotation:new()
    return setmetatable({}, ArrayNotation)
end

function ArrayNotation:format(n, places)
    local str = "{"

    local entries = #n:get_array()

    local decimals = math.max(3 - entries, 0)
    local shortening_point = 6 --6 array elements before we truncate
    local shorten = entries > shortening_point
    local i = 0
    for _,entry in pairs(n:get_array()) do
        i = i + 1
        if not shorten then
            local formatted = decimals > 0 and Notation.format_mantissa(entry, decimals) or math.floor(entry)
            str = str .. formatted .. (i ~= entries and ", " or "")
        else
            if i < 3 or i >= (entries - 1) then
                local formatted = decimals > 0 and Notation.format_mantissa(entry, decimals) or math.floor(entry)
                formatted = i .. ": " .. formatted
                str = str .. formatted .. (i ~= entries and ", " or "")
            end
        end
    end
    str = str .. "}"
    return str
end

return ArrayNotation