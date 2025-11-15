local mf = math.floor
function math.floor(x)
    if is_big(x) then return x:floor() end
    return mf(x)
end

local mc = math.ceil
function math.ceil(x)
    if is_big(x) then return x:ceil() end
    return mc(x)
end

local l10 = math.log10
function math.log10(x)
    if is_big(x) then x = x:to_number() end
    return l10(x)
end

local E = math.exp(1)

local log = math.log
function math.log(x, y)
	if is_big(x) then x = x:to_number() end
	if is_big(y) then y = y:to_number() end
    if y then return log(x, y) end
    return log(x)
end

function math.exp(x)
	if is_big(x) then x = x:to_number() end
    return E ^ x
end

local sqrt = math.sqrt
function math.sqrt(x)
    if is_big(x) then return x:pow(0.5) end
    return sqrt(x)
end

local old_abs = math.abs
function math.abs(x)
    if is_big(x) then return x:abs() end
    return old_abs(x)
end

--don't return a Big unless we have to - it causes nativefs to break
local max = math.max
function math.max(x, y)
    if is_big(x) or is_big(y) then
        x = to_big(x)
        y = to_big(y)
        if (x > y) then
            return x
        else
            return y
        end
    else
        return max(x, y)
    end
end

local min = math.min
function math.min(x, y)
    if is_big(x) or is_big(y) then
        x = to_big(x)
        y = to_big(y)
        if (x < y) then
            return x
        else
            return y
        end
    else
        return min(x, y)
    end
end
