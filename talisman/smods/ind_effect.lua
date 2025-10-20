local scie = SMODS.calculate_individual_effect
function SMODS.calculate_individual_effect(effect, scored_card, key, amount, from_edition)
  -- For some reason, some keys' animations are completely removed
  -- I think this is caused by a lovely patch conflict
  --if key == 'chip_mod' then key = 'chips' end
  --if key == 'mult_mod' then key = 'mult' end
  --if key == 'Xmult_mod' then key = 'x_mult' end
  local ret = scie(effect, scored_card, key, amount, from_edition)
  if ret then
    return ret
  end

  if (key == 'e_chips' or key == 'echips' or key == 'Echip_mod') and amount ~= 1 then
    if effect.card then juice_card(effect.card) end
    if SMODS.Scoring_Parameters then
      local chips = SMODS.Scoring_Parameters["chips"]
      chips:modify(chips.current ^ amount - chips.current)
    else
      hand_chips = mod_chips(hand_chips ^ amount)
      update_hand_text({delay = 0}, {chips = hand_chips, mult = mult})
    end
    if not effect.remove_default_message then
        if from_edition then
            card_eval_status_text(scored_card, 'jokers', nil, percent, nil, {message = "^"..amount, colour =  G.C.EDITION, edition = true})
        elseif key ~= 'Echip_mod' then
            if effect.echip_message then
                card_eval_status_text(effect.message_card or effect.juice_card or scored_card or effect.card or effect.focus, 'extra', nil, percent, nil, effect.echip_message)
            else
                card_eval_status_text(effect.message_card or effect.juice_card or scored_card or effect.card or effect.focus, 'e_chips', amount, percent)
            end
        end
    end
    return true
  end

  if (key == 'ee_chips' or key == 'eechips' or key == 'EEchip_mod') and amount ~= 1 then
    if effect.card then juice_card(effect.card) end
    if SMODS.Scoring_Parameters then
      local chips = SMODS.Scoring_Parameters["chips"]
      chips:modify(to_big(chips.current):tetrate(amount) - chips.current)
    else
      hand_chips = mod_chips(hand_chips:tetrate(amount))
      update_hand_text({delay = 0}, {chips = hand_chips, mult = mult})
    end
    if not effect.remove_default_message then
        if from_edition then
            card_eval_status_text(scored_card, 'jokers', nil, percent, nil, {message = "^^"..amount, colour =  G.C.EDITION, edition = true})
        elseif key ~= 'EEchip_mod' then
            if effect.eechip_message then
                card_eval_status_text(effect.message_card or effect.juice_card or scored_card or effect.card or effect.focus, 'extra', nil, percent, nil, effect.eechip_message)
            else
                card_eval_status_text(effect.message_card or effect.juice_card or scored_card or effect.card or effect.focus, 'ee_chips', amount, percent)
            end
        end
    end
    return true
  end

  if (key == 'eee_chips' or key == 'eeechips' or key == 'EEEchip_mod') and amount ~= 1 then
    if effect.card then juice_card(effect.card) end
    if SMODS.Scoring_Parameters then
      local chips = SMODS.Scoring_Parameters["chips"]
      chips:modify(to_big(chips.current):arrow(3, amount) - chips.current)
    else
      hand_chips = mod_chips(hand_chips:arrow(3, amount))
      update_hand_text({delay = 0}, {chips = hand_chips, mult = mult})
    end
    if not effect.remove_default_message then
        if from_edition then
            card_eval_status_text(scored_card, 'jokers', nil, percent, nil, {message = "^^^"..amount, colour =  G.C.EDITION, edition = true})
        elseif key ~= 'EEEchip_mod' then
            if effect.eeechip_message then
                card_eval_status_text(effect.message_card or effect.juice_card or scored_card or effect.card or effect.focus, 'extra', nil, percent, nil, effect.eeechip_message)
            else
                card_eval_status_text(effect.message_card or effect.juice_card or scored_card or effect.card or effect.focus, 'eee_chips', amount, percent)
            end
        end
    end
    return true
  end

  if (key == 'hyper_chips' or key == 'hyperchips' or key == 'hyperchip_mod') and type(amount) == 'table' then
    if effect.card then juice_card(effect.card) end
    if SMODS.Scoring_Parameters then
      local chips = SMODS.Scoring_Parameters["chips"]
      chips:modify(to_big(chips.current):arrow(amount[1], amount[2]) - chips.current)
    else
      hand_chips = mod_chips(hand_chips:arrow(amount[1], amount[2]))
      update_hand_text({delay = 0}, {chips = hand_chips, mult = mult})
    end
    if not effect.remove_default_message then
        if from_edition then
            card_eval_status_text(scored_card, 'jokers', nil, percent, nil, {message = (amount[1] > 5 and ('{' .. amount[1] .. '}') or string.rep('^', amount[1])) .. amount[2], colour =  G.C.EDITION, edition = true})
        elseif key ~= 'hyperchip_mod' then
            if effect.hyperchip_message then
                card_eval_status_text(effect.message_card or effect.juice_card or scored_card or effect.card or effect.focus, 'extra', nil, percent, nil, effect.hyperchip_message)
            else
                card_eval_status_text(effect.message_card or effect.juice_card or scored_card or effect.card or effect.focus, 'hyper_chips', amount, percent)
            end
        end
    end
    return true
  end

  if (key == 'e_mult' or key == 'emult' or key == 'Emult_mod') and amount ~= 1 then
    if effect.card then juice_card(effect.card) end
    if SMODS.Scoring_Parameters then
      local mult = SMODS.Scoring_Parameters["mult"]
      mult:modify(mult.current ^ amount - mult.current)
    else
      mult = mod_mult(mult ^ amount)
      update_hand_text({delay = 0}, {chips = hand_chips, mult = mult})
    end
    if not effect.remove_default_message then
        if from_edition then
            card_eval_status_text(scored_card, 'jokers', nil, percent, nil, {message = "^"..amount.." "..localize("k_mult"), colour =  G.C.EDITION, edition = true})
        elseif key ~= 'Emult_mod' then
            if effect.emult_message then
                card_eval_status_text(effect.message_card or effect.juice_card or scored_card or effect.card or effect.focus, 'extra', nil, percent, nil, effect.emult_message)
            else
                card_eval_status_text(effect.message_card or effect.juice_card or scored_card or effect.card or effect.focus, 'e_mult', amount, percent)
            end
        end
    end
    return true
  end

  if (key == 'ee_mult' or key == 'eemult' or key == 'EEmult_mod') and amount ~= 1 then
    if effect.card then juice_card(effect.card) end
    if SMODS.Scoring_Parameters then
      local mult = SMODS.Scoring_Parameters["mult"]
      mult:modify(to_big(mult.current):arrow(2, amount) - mult.current)
    else
      mult = mod_mult(mult:arrow(2, amount))
      update_hand_text({delay = 0}, {chips = hand_chips, mult = mult})
    end
    if not effect.remove_default_message then
        if from_edition then
            card_eval_status_text(scored_card, 'jokers', nil, percent, nil, {message = "^^"..amount.." "..localize("k_mult"), colour =  G.C.EDITION, edition = true})
        elseif key ~= 'EEmult_mod' then
            if effect.eemult_message then
                card_eval_status_text(effect.message_card or effect.juice_card or scored_card or effect.card or effect.focus, 'extra', nil, percent, nil, effect.eemult_message)
            else
                card_eval_status_text(effect.message_card or effect.juice_card or scored_card or effect.card or effect.focus, 'ee_mult', amount, percent)
            end
        end
    end
    return true
  end

  if (key == 'eee_mult' or key == 'eeemult' or key == 'EEEmult_mod') and amount ~= 1 then
    if effect.card then juice_card(effect.card) end
    if SMODS.Scoring_Parameters then
      local mult = SMODS.Scoring_Parameters["mult"]
      mult:modify(to_big(mult.current):arrow(3, amount) - mult.current)
    else
      mult = mod_mult(mult:arrow(3, amount))
      update_hand_text({delay = 0}, {chips = hand_chips, mult = mult})
    end
    if not effect.remove_default_message then
        if from_edition then
            card_eval_status_text(scored_card, 'jokers', nil, percent, nil, {message = "^^^"..amount.." "..localize("k_mult"), colour =  G.C.EDITION, edition = true})
        elseif key ~= 'EEEmult_mod' then
            if effect.eeemult_message then
                card_eval_status_text(effect.message_card or effect.juice_card or scored_card or effect.card or effect.focus, 'extra', nil, percent, nil, effect.eeemult_message)
            else
                card_eval_status_text(effect.message_card or effect.juice_card or scored_card or effect.card or effect.focus, 'eee_mult', amount, percent)
            end
        end
    end
    return true
  end

  if (key == 'hyper_mult' or key == 'hypermult' or key == 'hypermult_mod') and type(amount) == 'table' then
    if effect.card then juice_card(effect.card) end
    if SMODS.Scoring_Parameters then
      local mult = SMODS.Scoring_Parameters["mult"]
      mult:modify(to_big(mult.current):arrow(amount[1], amount[2]) - mult.current)
    else
      mult = mod_mult(mult:arrow(amount[1], amount[2]))
      update_hand_text({delay = 0}, {chips = hand_chips, mult = mult})
    end
    if not effect.remove_default_message then
        if from_edition then
            card_eval_status_text(scored_card, 'jokers', nil, percent, nil, {message = ((amount[1] > 5 and ('{' .. amount[1] .. '}') or string.rep('^', amount[1])) .. amount[2]).." "..localize("k_mult"), colour =  G.C.EDITION, edition = true})
        elseif key ~= 'hypermult_mod' then
            if effect.hypermult_message then
                card_eval_status_text(effect.message_card or effect.juice_card or scored_card or effect.card or effect.focus, 'extra', nil, percent, nil, effect.hypermult_message)
            else
                card_eval_status_text(effect.message_card or effect.juice_card or scored_card or effect.card or effect.focus, 'hyper_mult', amount, percent)
            end
        end
    end
    return true
  end
end

for _, v in ipairs({'e_mult', 'e_chips', 'ee_mult', 'ee_chips', 'eee_mult', 'eee_chips', 'hyper_mult', 'hyper_chips',
                    'emult', 'echips', 'eemult', 'eechips', 'eeemult', 'eeechips', 'hypermult', 'hyperchips',
                    'Emult_mod', 'Echip_mod', 'EEmult_mod', 'EEchip_mod', 'EEEmult_mod', 'EEEchip_mod', 'hypermult_mod', 'hyperchip_mod'}) do
  table.insert(SMODS.scoring_parameter_keys or SMODS.calculation_keys, v)
end

-- prvent juice animations
local smce = SMODS.calculate_effect
function SMODS.calculate_effect(effect, ...)
  if Talisman.config_file.disable_anims then effect.juice_card = nil end
  return smce(effect, ...)
end