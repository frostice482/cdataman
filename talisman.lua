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
local function load_file_with_fallback2(a, aa)
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

local g_start_run = Game.start_run
function Game:start_run(args)
  local ret = g_start_run(self, args)
  self.GAME.round_resets.ante_disp = self.GAME.round_resets.ante_disp or number_format(self.GAME.round_resets.ante)
  return ret
end

require("talisman.globals")
require("talisman.break_inf")
require("talisman.card")
require("talisman.configtab")
require("talisman.noanims")
require("talisman.safety")
if not Talisman.F_NO_COROUTINE then
  require("talisman.coroutine")
end