local cest = card_eval_status_text
function card_eval_status_text(a,b,c,d,e,f)
    if not Talisman.config_file.disable_anims then cest(a,b,c,d,e,f) end
end

local jc = juice_card
function juice_card(x)
    if not Talisman.config_file.disable_anims then jc(x) end
end

local cju = Card.juice_up
function Card:juice_up(...)
    if not Talisman.config_file.disable_anims then cju(self, ...) end
end

local uht = update_hand_text
function update_hand_text(config, vals)
    if not Talisman.config_file.disable_anims then uht(config, vals) end
    if G.latest_uht then
      local chips = G.latest_uht.vals.chips
      local mult = G.latest_uht.vals.mult
      if not vals.chips then vals.chips = chips end
      if not vals.mult then vals.mult = mult end
    end
    G.latest_uht = {config = config, vals = vals}
end

function tal_uht(config, vals)
    local col = G.C.GREEN
    if vals.chips and G.GAME.current_round.current_hand.chips ~= vals.chips then
        local delta = (is_number(vals.chips) and is_number(G.GAME.current_round.current_hand.chips)) and (vals.chips - G.GAME.current_round.current_hand.chips) or 0
        if to_big(delta) < BigC.ZERO then delta = number_format(delta); col = G.C.RED
        elseif to_big(delta) > BigC.ZERO then delta = '+'..number_format(delta)
        else delta = number_format(delta)
        end
        if type(vals.chips) == 'string' then delta = vals.chips end
        G.GAME.current_round.current_hand.chips = vals.chips
        if G.hand_text_area.chips.config.object then
          G.hand_text_area.chips:update(0)
        end
    end
    if vals.mult and G.GAME.current_round.current_hand.mult ~= vals.mult then
        local delta = (is_number(vals.mult) and is_number(G.GAME.current_round.current_hand.mult))and (vals.mult - G.GAME.current_round.current_hand.mult) or 0
        if to_big(delta) < BigC.ZERO then delta = number_format(delta); col = G.C.RED
        elseif to_big(delta) > BigC.ZERO then delta = '+'..number_format(delta)
        else delta = number_format(delta)
        end
        if type(vals.mult) == 'string' then delta = vals.mult end
        G.GAME.current_round.current_hand.mult = vals.mult
        if G.hand_text_area.mult.config.object then
          G.hand_text_area.mult:update(0)
        end
    end
    if vals.handname and G.GAME.current_round.current_hand.handname ~= vals.handname then
        G.GAME.current_round.current_hand.handname = vals.handname
    end
    if vals.chip_total then G.GAME.current_round.current_hand.chip_total = vals.chip_total;G.hand_text_area.chip_total.config.object:pulse(0.5) end
    if vals.level and G.GAME.current_round.current_hand.hand_level ~= ' '..localize('k_lvl')..tostring(vals.level) then
        if vals.level == '' then
            G.GAME.current_round.current_hand.hand_level = vals.level
        else
            G.GAME.current_round.current_hand.hand_level = ' '..localize('k_lvl')..tostring(vals.level)
            if is_number(vals.level) then
                G.hand_text_area.hand_level.config.colour = G.C.HAND_LEVELS[type(vals.level) == "number" and math.floor(math.min(vals.level, 7)) or math.floor(to_number(math.min(vals.level, 7)))]
            else
                G.hand_text_area.hand_level.config.colour = G.C.HAND_LEVELS[1]
            end
        end
    end
    return true
end

local gfer = G.FUNCS.evaluate_round
function G.FUNCS.evaluate_round()
  if not Talisman.config_file.disable_anims then return gfer() end

  if to_big(G.GAME.chips) >= to_big(G.GAME.blind.chips) then
      add_round_eval_row({dollars = G.GAME.blind.dollars, name='blind1', pitch = 0.95})
  else
      add_round_eval_row({dollars = 0, name='blind1', pitch = 0.95, saved = true})
  end
  local arer = add_round_eval_row
  add_round_eval_row = function() return end
  local dollars = gfer()
  add_round_eval_row = arer
  add_round_eval_row({name = 'bottom', dollars = Talisman.dollars})
end