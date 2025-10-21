local lovely = require("lovely")
local nativefs = require("nativefs")

local info = nativefs.getDirectoryItemsInfo(lovely.mod_dir)
local talisman_path = ""
for i, v in pairs(info) do
  if nativefs.getInfo(lovely.mod_dir .. "/" .. v.name .. "/talisman.lua") then talisman_path = lovely.mod_dir .. "/" .. v.name end
end

if not nativefs.getInfo(talisman_path) then
    error('Could not find proper Talisman folder.\nPlease make sure that Talisman is installed correctly and the folders arent nested.')
end

nativefs.mount(talisman_path..'/talisman', 'talisman')
nativefs.mount(talisman_path..'/big-num', 'big-num')

-- "Borrowed" from Trance
function load_file_with_fallback2(a, aa)
    local success, result = pcall(function() return assert(nativefs.load(a))() end)
    if success then
        return result
    end
    local fallback_success, fallback_result = pcall(function() return assert(nativefs.load(aa))() end)
    if fallback_success then
        return fallback_result
    end
end

local talismanloc = init_localization
function init_localization()
	local abc = load_file_with_fallback2(
		talisman_path.."/localization/" .. (G.SETTINGS.language or "en-us") .. ".lua",
		talisman_path .. "/localization/en-us.lua"
	)
	for k, v in pairs(abc) do
		if k ~= "descriptions" then
			G.localization.misc.dictionary[k] = v
		end
		-- todo error messages(?)
		G.localization.misc.dictionary[k] = v
	end
	talismanloc()
end

Talisman = {
  config_file = {
    disable_anims = false,
    break_infinity = "omeganum",
    score_opt_id = 2
  },
  mod_path = talisman_path,
  F_NO_COROUTINE = false
}

local conf = nativefs.read(talisman_path.."/config.lua")
if conf then
    Talisman.config_file = STR_UNPACK(conf)
    if Talisman.config_file.break_infinity == "bignumber" then
      Talisman.config_file.break_infinity = "omeganum"
      Talisman.config_file.score_opt_id = 2
    end
    if Talisman.config_file.score_opt_id == 3 then
      Talisman.config_file.score_opt_id = 2
    end
    if Talisman.config_file.break_infinity and type(Talisman.config_file.break_infinity) ~= 'string' then
      Talisman.config_file.break_infinity = "omeganum"
    end
end

function is_big(x)
  return Big and Big.is(x)
end

function is_number(x)
  if type(x) == 'number' then return true end
  if is_big(x) then return true end
  return false
end

--- @return t.Omega | number
function to_big(x, y)
  if type(x) == 'string' and x == "0" then --hack for when 0 is asked to be a bignumber need to really figure out the fix
    return 0
  elseif Big and Big.m then
    local x = Big:new(x,y)
    return x
  elseif Big and Big.array then
    local result = Big:create(x)
    if y then result.sign = y end
    return result
  elseif is_number(x) then
    return x * 10^(y or 0)

  elseif type(x) == "nil" then
    return 0
  else
    if ((#x>=2) and ((x[2]>=2) or (x[2]==1) and (x[1]>308))) then
      return 1e309
    end
    if (x[2]==1) then
      return math.pow(10,x[1])
    end
    return x[1]*(y or 1);
  end
end

function to_number(x)
  if Big and Big.is(x) then
    return x:to_number()
  else
    return x
  end
end

function uncompress_big(str, sign)
    local curr = 1
    local array = {}
    for i, v in pairs(str) do
        for i2 = 1, v[2] do
            array[curr] = v[1]
            curr = curr + 1
        end
    end
    return to_big(array, y)
end

function lenient_bignum(x)
    return x
end

--patch to remove animations


G.FUNCS.evaluate_play = function(e)
  Talisman.scoring_state = "intro"
  text, disp_text, poker_hands, scoring_hand, non_loc_disp_text, percent, percent_delta = evaluate_play_intro()
  if not G.GAME.blind:debuff_hand(G.play.cards, poker_hands, text) then
    Talisman.scoring_state = "main"
    text, disp_text, poker_hands, scoring_hand, non_loc_disp_text, percent, percent_delta = evaluate_play_main(text, disp_text, poker_hands, scoring_hand, non_loc_disp_text, percent, percent_delta)
  else
    Talisman.scoring_state = "debuff"
    text, disp_text, poker_hands, scoring_hand, non_loc_disp_text, percent, percent_delta = evaluate_play_debuff(text, disp_text, poker_hands, scoring_hand, non_loc_disp_text, percent, percent_delta)
  end
  Talisman.scoring_state = "final_scoring"
  text, disp_text, poker_hands, scoring_hand, non_loc_disp_text, percent, percent_delta = evaluate_play_final_scoring(text, disp_text, poker_hands, scoring_hand, non_loc_disp_text, percent, percent_delta)
  Talisman.scoring_state = "after"
  evaluate_play_after(text, disp_text, poker_hands, scoring_hand, non_loc_disp_text, percent, percent_delta)
  Talisman.scoring_state = nil
end

local upd = Game.update
function Game:update(dt)
    upd(self, dt)
    if G.latest_uht and G.latest_uht.config and G.latest_uht.vals then
        tal_uht(G.latest_uht.config, G.latest_uht.vals)
        G.latest_uht = nil
    end
    if Talisman.dollar_update then
      G.HUD:get_UIE_by_ID('dollar_text_UI').config.object:update()
      G.HUD:recalculate()
      Talisman.dollar_update = false
    end
end

local gfep = G.FUNCS.evaluate_play
G.FUNCS.evaluate_play = function(e)
	Talisman.calculating_score = true
	local ret = gfep(e)
	Talisman.calculating_score = false
	return ret
end

--Easing fixes
--Changed this to always work; it's less pretty but fine for held in hand things
local edo = ease_dollars
function ease_dollars(mod, instant)
  if Talisman.config_file.disable_anims then--and (Talisman.calculating_joker or Talisman.calculating_score or Talisman.calculating_card) then
    mod = mod or 0
    if to_big(mod) > BigC.ZERO then inc_career_stat('c_dollars_earned', mod) end
    G.GAME.dollars = G.GAME.dollars + mod
    Talisman.dollar_update = true
  else return edo(mod, instant) end
end

local g_start_run = Game.start_run
function Game:start_run(args)
  local ret = g_start_run(self, args)
  self.GAME.round_resets.ante_disp = self.GAME.round_resets.ante_disp or number_format(self.GAME.round_resets.ante)
  return ret
end

--some debugging functions
--[[local callstep=0
function printCallerInfo()
  -- Get debug info for the caller of the function that called printCallerInfo
  local info = debug.getinfo(3, "Sl")
  callstep = callstep+1
  if info then
      print("["..callstep.."] "..(info.short_src or "???")..":"..(info.currentline or "unknown"))
  else
      print("Caller information not available")
  end
end
local emae = EventManager.add_event
function EventManager:add_event(x,y,z)
  printCallerInfo()
  return emae(self,x,y,z)
end--]]

require("talisman.break_inf")
require("talisman.card")
require("talisman.configtab")
require("talisman.noanims")
require("talisman.safety")
if not Talisman.F_NO_COROUTINE then
  require("talisman.coroutine")
end