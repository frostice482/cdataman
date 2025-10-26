-- DynaText: reuse already allocated letters

local gtextcache = setmetatable({}, { __mode = 'k' })
DynaText.gtextcache = gtextcache

function DynaText._global_get_text_cache(font, letter)
    if not gtextcache[font] then gtextcache[font] = setmetatable({}, { __mode = 'v' }) end
    local set = gtextcache[font]
    local text = set[letter]
    if not text then
        text = love.graphics.newText(font, letter)
        set[letter] = text
    end
    return text
end

-- GC

local mgc_interval = 30 -- milliseconds
local mgc_boost_min = 50 -- minimum MB to increase step
local mgc_boost_mult = 6 -- step multiplier per MB
local nextGc = 0

local _nuGC = nuGC
function nuGC()
    if Talisman.config_file.disable_gcv2 then return _nuGC() end

    collectgarbage("step", 1)

    local t = love.timer.getTime()
    if t >= nextGc then
        nextGc = t + mgc_interval / 1000
        local mem = collectgarbage("count")
        local boost = (mem / 1024 - mgc_boost_min) * mgc_boost_mult
        collectgarbage("step", 1 + math.max(boost, 0))
    end

    collectgarbage("stop")
end

local update = Game.update
function Game:update(dt)
    update(self, dt)
    collectgarbage("stop")
end