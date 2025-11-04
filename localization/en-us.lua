return {
    descriptions = {
        Mod = {
            Talisman = {
                name = "Talisman",
                text = { "A mod that increases Balatro's score limit and skips scoring animations." },
            }
        }
    },
    test = "j",

    tal_disable_anim = 'Disable Scoring Animations',
    tal_disable_omega = 'Disable OmegaNum (requires restart)',
    tal_enable_compat = 'Enable type compat',
    tal_enable_compat_warning = {
        'Warning: Type compat does not work with some mods,',
        'and instead will cause unexpected crash when enabled.'
    },
    tal_calculating = 'Calculating...',
    tal_abort = 'Abort',
    tal_elapsed = 'Elapsed calculations',
    tal_current_state = 'Currently scoring',
    tal_card_prog = 'Scored card progress',
    tal_luamem = 'Lua memory',
    tal_last_elapsed = 'Calculations last played hand',
    tal_unknown = 'Unknown',

    --These don't work out of the box because they would be called too early, find a workaround later?
    talisman_error_A = 'Could not find proper Talisman folder. Please make sure the folder for Talisman is named exactly "Talisman" and not "Talisman-main" or anything else.',
    talisman_error_B = '[Talisman] Error unpacking string: ',
    talisman_error_C = '[Talisman] Error loading string: '
}
