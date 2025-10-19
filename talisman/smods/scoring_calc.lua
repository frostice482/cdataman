local ref = SMODS.set_scoring_calculation
function SMODS.set_scoring_calculation(key, ...)
	G.GAME.current_scoring_calculation_key = key
	if key == "talisman_hyper" then
		G.GAME.hyper_operator = G.GAME.hyper_operator or 2
	end
	return ref(key, ...)
end

SMODS.Scoring_Calculation:take_ownership("add", { order = -1 }, true)
SMODS.Scoring_Calculation:take_ownership("multiply", { order = 0 }, true)
SMODS.Scoring_Calculation:take_ownership("exponent", { order = 1 }, true)
SMODS.Scoring_Calculation {
	key = "hyper",
	func = function(self, chips, mult, flames) return to_big(chips):arrow(G.GAME.hyper_operator or 2, mult) end,
	text = function()
		if G.GAME.hyper_operator < 6 then
			local str = ""
			for i = 1, G.GAME.hyper_operator do str = str .. "^" end
			return str
		else
			return "{" .. G.GAME.hyper_operator .. "}"
		end
	end,
	order = 2
}

function change_operator(amount)
	local order = SMODS.Scoring_Calculations[G.GAME.current_scoring_calculation_key or "multiply"].order + amount
	if not order then return end
	if G.GAME.current_scoring_calculation_key == "talisman_hyper" then
		G.GAME.hyper_operator = (G.GAME.hyper_operator or 2) + amount
		order = G.GAME.hyper_operator
	end
	local next = "add"
	local keys = {}
	for i, v in pairs(SMODS.Scoring_Calculations) do
		if v.order then
			keys[#keys + 1] = i
		end
	end
	table.sort(keys, function(a, b)
		return SMODS.Scoring_Calculations[a].order < SMODS.Scoring_Calculations[b].order
	end)
	for i, v in pairs(keys) do
		if SMODS.Scoring_Calculations[v].order <= order then
			next = v
		end
	end
	if next then
		SMODS.set_scoring_calculation(next)
	end
end
