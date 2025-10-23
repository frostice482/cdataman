return {
        descriptions = {
                Mod = {
                        Talisman = {
                                name = "Talisman",
                                text = {"A mod that increases Balatro's score limit and skips scoring animations."},
                        }
                }
        },
        test = "q",
        talisman_vanilla = 'Vanilla (e308)',
        talisman_bignum = 'BigNum (ee308)',
        talisman_omeganum = 'OmegaNum',

        tal_feature_select = 'Select features to enable:',
        tal_disable_anim = 'Disable Scoring Animations',
        tal_score_limit = 'Score Limit (requires game restart)',
        tal_calculating = 'Calculating...',
        tal_abort = 'Abort',
        tal_elapsed = 'Elapsed calculations: ',
        tal_remaining = 'Cards yet to score: ',
        tal_last_elapsed = 'Calculations last played hand: ',
        tal_unknown = 'Unknown',

        --These don't work out of the box because they would be called too early, find a workaround later?
        talisman_error_A = 'Could not find proper Talisman folder. Please make sure the folder for Talisman is named exactly "Talisman" and not "Talisman-main" or anything else.',
        talisman_error_B = '[Talisman] Error unpacking string: ',
        talisman_error_C = '[Talisman] Error loading string: ',
}
