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

local sm = Card.start_materialize
function Card:start_materialize(a,b,c)
    if Talisman.config_file.disable_anims and (Talisman.calculating_joker or Talisman.calculating_score or Talisman.calculating_card) then return end
    return sm(self,a,b,c)
end

local sd = Card.start_dissolve
function Card:start_dissolve(a,b,c,d)
    if Talisman.config_file.disable_anims and (Talisman.calculating_joker or Talisman.calculating_score or Talisman.calculating_card) then self:remove() return end
    return sd(self,a,b,c,d)
end

local ss = Card.set_seal
function Card:set_seal(a,b,immediate)
    return ss(self,a,b,Talisman.config_file.disable_anims and (Talisman.calculating_joker or Talisman.calculating_score or Talisman.calculating_card) or immediate)
end

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