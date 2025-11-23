Big = require("big-num.omeganum")
Notations = require("big-num.notations")

for k,v in pairs(BigC) do
    BigC[k] = Big:create(v)
end
local constants = require("big-num.constants")
BigC.E_MAX_SAFE_INTEGER = Big:create(constants.E_MAX_SAFE_INTEGER)

-- wow...
local _t = type
function type(v)
    return Talisman.config_file.enable_compat and Big and Big.is(v) and "table" or _t(v)
end

local tsj = G.FUNCS.text_super_juice
function G.FUNCS.text_super_juice(e, _amount)
    if _amount > 10 then _amount = 10 end
    return tsj(e, _amount)
end

-- We call this after init_game_object to leave room for mods that add more poker hands
Talisman.igo = function(obj)
    for _, v in pairs(obj.hands) do
        v.chips = to_big(v.chips)
        v.mult = to_big(v.mult)
        v.s_chips = to_big(v.s_chips)
        v.s_mult = to_big(v.s_mult)
        v.l_chips = to_big(v.l_chips)
        v.l_mult = to_big(v.l_mult)
        v.level = to_big(v.level)
    end
    obj.starting_params.dollars = to_big(obj.starting_params.dollars)
    return obj
end

local nf = number_format
function number_format(num, e_switch_point)
    if not is_big(num) then return nf(num, e_switch_point) end
    local notation = Notations[Talisman.config_file.notation or 'Balatro'] or Notations.Balatro
    if num.asize > 2 then
        return notation:format(num, 3)
    end
    if num < G.E_SWITCH_POINT then
        return nf(num:to_number(), e_switch_point)
    end
    return notation:format(num, 3)
end

require("talisman.break_math")

function lenient_bignum(x)
    if not x or type(x) == "number" then return x end
    if x < BigC.BIG and x > BigC.NBIG then return x:to_number() end
    return x
end

--prevent some log-related crashes
local sns = score_number_scale
function score_number_scale(scale, amt)
    local ret = sns(scale, amt)
    if is_big(ret) then
        if ret > BigC.BIG then return constants.BIG end
        return ret:to_number()
    end
    return ret
end

local gftsj = G.FUNCS.text_super_juice
function G.FUNCS.text_super_juice(e, _amount)
    if is_big(_amount) then
        if _amount > BigC.BIG then
            _amount = constants.BIG
        else
            _amount = _amount:to_number()
        end
    end
    return gftsj(e, _amount)
end

local B100 = to_big(100)
local k = to_big(0.75)

local amts = {
    { 300, 800, 2000, 5000, 11000, 20000, 35000, 50000 },
    { 300, 900, 2600, 8000, 20000, 36000, 60000, 100000 },
    { 300, 1000, 3200, 9000, 25000, 60000, 110000, 200000 },
}
for i, list in ipairs(amts) do
    for j, chips in ipairs(list) do
        list[j] = to_big(chips)
    end
end

-- There's too much to override here so we just fully replace this function
-- Note that any ante scaling tweaks will need to manually changed...
local gba = get_blind_amount
function get_blind_amount(ante)
    if not Big then return gba(ante) end

    local amounts = amts[G.GAME.modifiers.scaling or 1]
    if not amounts then
        if SMODS then return SMODS.get_blind_amount(ante)
        else return 0 end
    end

    if ante < 1 then return B100 end
    if ante <= 8 then return amounts[ante] end

    local a, b, c, d = amounts[8], 1.6, ante - 8, 1 + 0.2 * (ante - 8)
    local amount = a * (b + (k * c) ^ d) ^ c
    if (amount:lt(BigC.E_MAX_SAFE_INTEGER)) then
        local exponent = to_big(10) ^ (math.floor(amount:log10() - to_big(1))):to_number()
        amount = math.floor(amount / exponent):to_number() * exponent
    end
    amount:normalize()
    return amount
end

function check_and_set_high_score(score, amt)
    amt = math.floor(amt)
    local hs = G.PROFILES[G.SETTINGS.profile].high_scores[score]
    local rs = G.GAME.round_scores[score]
    if rs and amt > rs.amt then
        rs.amt = amt
    end
    if G.GAME.seeded then return end

    if hs and math.floor(amt) > hs.amt then
        if rs then rs.high_score = true end
        hs.amt = amt
        G:save_settings()
    end
end

local ics = inc_career_stat
-- This is used often for unlocks, so we can't just prevent big money from being added
-- Also, I'm completely overriding this, since I don't think any mods would want to change it
function inc_career_stat(stat, mod)
    if G.GAME.seeded or G.GAME.challenge then return end
    local stats = G.PROFILES[G.SETTINGS.profile].career_stats

    if not stats[stat] then stats[stat] = 0 end
    stats[stat] = stats[stat] + (mod or 0)
    -- Make sure this isn't ever a talisman number
    if is_big(stats[stat]) then
        if stats[stat] > BigC.BIG then
            stats[stat] = BigC.BIG
        elseif stats[stat] < BigC.NBIG then
            stats[stat] = BigC.NBIG
        end
        stats[stat] = stats[stat]:to_number()
    end

    G:save_settings()
end

local sn = scale_number
function scale_number(number, scale, max, e_switch_point)
    if not number or not is_number(number) then return scale end
    if not Big then return sn(number, scale, max, e_switch_point) end

    if not max then max = 10000 end
    if not is_big(scale) then
        scale = to_big(scale)
    end
    if not is_big(number) then
        number = Big:ensureBig(number)
    end

    if not e_switch_point and number.asize > 2 then             --this is noticable faster than >= on the raw number for some reason
        if number.asize <= 2 and (number:get_array()[1] or 0) <= 999 then --gross hack
            scale = scale * math.floor(math.log(max * 10, 10)) / 7    --this divisor is a constant so im precalcualting it
        else
            scale = scale * math.floor(math.log(max * 10, 10)) /
            math.floor(math.max(7, string.len(number_format(number)) - 1))
        end
    elseif to_big(number) >= (e_switch_point and to_big(e_switch_point) or G.E_SWITCH_POINT) then
        if number.asize <= 2 and (number:get_array()[1] or 0) <= 999 then --gross hack
            scale = scale * math.floor(math.log(max * 10, 10)) / 7    --this divisor is a constant so im precalcualting it
        else
            scale = scale * math.floor(math.log(max * 10, 10)) /
            math.floor(math.max(7, string.len(number_format(number)) - 1))
        end
    elseif to_big(number) >= to_big(max) then
        scale = scale * math.floor(math.log(max * 10, 10)) / math.floor(math.log(number * 10, 10))
    end

    scale = math.min(3, scale:to_number())
    return scale
end

if SMODS then
    function SMODS.get_blind_amount(ante)
        if ante < 1 then return to_big(100) end
        local scale = G.GAME.modifiers.scaling
        local amounts = {
            to_big(300),
            to_big(700 + 100 * scale),
            to_big(1400 + 600 * scale),
            to_big(2100 + 2900 * scale),
            to_big(15000 + 5000 * scale * math.log(scale)),
            to_big(12000 + 8000 * (scale + 1) * (0.4 * scale)),
            to_big(10000 + 25000 * (scale + 1) * ((scale / 4) ^ 2)),
            to_big(50000 * (scale + 1) ^ 2 * (scale / 7) ^ 2)
        }

        local amount
        if ante <= 8 then
            amount = amounts[ante]
        else
            local a, b, c, d = amounts[8], amounts[8] / amounts[7], ante - 8, 1 + 0.2 * (ante - 8)
            amount = math.floor(a * (b + (b * k * c) ^ d) ^ c)
        end

        if (amount:lt(BigC.E_MAX_SAFE_INTEGER)) then
            local exponent = to_big(10) ^ (math.floor(amount:log10() - to_big(1))):to_number()
            amount = math.floor(amount / exponent):to_number() * exponent
        end
        amount:normalize()
        return amount
    end
end

G.SAVED_GAME = nil