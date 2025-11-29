local nativefs = require("nativefs")
local talisman_path = _mod_dir_amulet

assert(nativefs.mount(talisman_path..'/talisman', 'talisman'))
assert(nativefs.mount(talisman_path..'/big-num', 'big-num'))

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
  mod_path = talisman_path,
  F_NO_COROUTINE = false,
  Amulet = true
}
Talisman.config_file = {
  disable_anims = false,
  break_infinity = "omeganum",
  notation = "Balatro"
}
Talisman.notations = {
  loc_keys = {
    "talisman_notations_hypere",
    --"talisman_notations_letter",
    "talisman_notations_array",
    --"k_ante"
  },
  filenames = {
    "Balatro",
    --"LetterNotation",
    "ArrayNotation",
    --"AnteNotation",
  }
}

local conf = nativefs.read(talisman_path.."/config.lua")
if conf then
  local parsed = STR_UNPACK(conf)
  if parsed then
    for k,v in pairs(parsed) do
      Talisman.config_file[k] = v
    end
  end
end

local g_start_run = Game.start_run
function Game:start_run(args)
  local ret = g_start_run(self, args)
  self.GAME.round_resets.ante_disp = self.GAME.round_resets.ante_disp or number_format(self.GAME.round_resets.ante)
  return ret
end

require("talisman.globals")
require("talisman.card")
require("talisman.configtab")
require("talisman.noanims")
require("talisman.safety")
require("talisman.debug")
if not Talisman.config_file.disable_omega then
  require("talisman.break_inf")
end
if not Talisman.F_NO_COROUTINE then
  require("talisman.coroutine")
end