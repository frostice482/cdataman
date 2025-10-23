--[[local ec = eval_card
function eval_card()
  Talisman.calculating_card = true
  local ret = ec()
  Talisman.calculating_card = false
  return ret
end--]]

function Card:get_chip_e_bonus()
    if self.debuff then return 0 end
    if self.ability.set == 'Joker' then return 0 end
    if (self.ability.e_chips or 0) <= 1 then return 0 end
    return self.ability.e_chips
end

function Card:get_chip_ee_bonus()
    if self.debuff then return 0 end
    if self.ability.set == 'Joker' then return 0 end
    if (self.ability.ee_chips or 0) <= 1 then return 0 end
    return self.ability.ee_chips
end

function Card:get_chip_eee_bonus()
    if self.debuff then return 0 end
    if self.ability.set == 'Joker' then return 0 end
    if (self.ability.eee_chips or 0) <= 1 then return 0 end
    return self.ability.eee_chips
end

function Card:get_chip_hyper_bonus()
    if self.debuff then return {0,0} end
    if self.ability.set == 'Joker' then return {0,0} end
	if type(self.ability.hyper_chips) ~= 'table' then return {0,0} end
    if (self.ability.hyper_chips[1] <= 0 or self.ability.hyper_chips[2] <= 0) then return {0,0} end
    return self.ability.hyper_chips
end

function Card:get_chip_e_mult()
    if self.debuff then return 0 end
    if self.ability.set == 'Joker' then return 0 end
    if (self.ability.e_mult or 0) <= 1 then return 0 end
    return self.ability.e_mult
end

function Card:get_chip_ee_mult()
    if self.debuff then return 0 end
    if self.ability.set == 'Joker' then return 0 end
    if (self.ability.ee_mult or 0) <= 1 then return 0 end
    return self.ability.ee_mult
end

function Card:get_chip_eee_mult()
    if self.debuff then return 0 end
    if self.ability.set == 'Joker' then return 0 end
    if (self.ability.eee_mult or 0) <= 1 then return 0 end
    return self.ability.eee_mult
end

function Card:get_chip_hyper_mult()
    if self.debuff then return {0,0} end
    if self.ability.set == 'Joker' then return {0,0} end
	if type(self.ability.hyper_mult) ~= 'table' then return {0,0} end
    if (self.ability.hyper_mult[1] <= 0 or self.ability.hyper_mult[2] <= 0) then return {0,0} end
    return self.ability.hyper_mult
end

local cuc = Card.use_consumable
function Card:use_consumable(x,y)
	Talisman.calculating_score = true
	local ret = cuc(self, x,y)
	Talisman.calculating_score = false
	return ret
end

if not SMODS then
  function Card:get_chip_x_bonus()
      if self.debuff then return 0 end
      if self.ability.set == 'Joker' then return 0 end
      if (self.ability.x_chips or 0) <= 1 then return 0 end
      return self.ability.x_chips
  end
end
