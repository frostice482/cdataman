local lovely = require("lovely")
local nativefs = require("nativefs")
Notations = {
    BaseLetterNotation = nativefs.load(Talisman.mod_path.."/big-num/notations/baseletternotation.lua")(),
    LetterNotation = nativefs.load(Talisman.mod_path.."/big-num/notations/letternotation.lua")(),
    CyrillicNotation = nativefs.load(Talisman.mod_path.."/big-num/notations/cyrillicnotation.lua")(),
    GreekNotation = nativefs.load(Talisman.mod_path.."/big-num/notations/greeknotation.lua")(),
    HebrewNotation = nativefs.load(Talisman.mod_path.."/big-num/notations/hebrewnotation.lua")(),
    ScientificNotation = nativefs.load(Talisman.mod_path.."/big-num/notations/scientificnotation.lua")(),
    EngineeringNotation = nativefs.load(Talisman.mod_path.."/big-num/notations/engineeringnotation.lua")(),
    BaseStandardNotation = nativefs.load(Talisman.mod_path.."/big-num/notations/basestandardnotation.lua")(),
    StandardNotation = nativefs.load(Talisman.mod_path.."/big-num/notations/standardnotation.lua")(),
    ThousandNotation = nativefs.load(Talisman.mod_path.."/big-num/notations/thousandnotation.lua")(),
    DynamicNotation = nativefs.load(Talisman.mod_path.."/big-num/notations/dynamicnotation.lua")(),
    Balatro = nativefs.load(Talisman.mod_path.."/big-num/notations/Balatro.lua")(),
    ArrayNotation = nativefs.load(Talisman.mod_path.."/big-num/notations/arraynotation.lua")(),
}

return Notations
