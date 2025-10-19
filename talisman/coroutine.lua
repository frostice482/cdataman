--scoring coroutine
local oldplay = G.FUNCS.evaluate_play
function G.FUNCS.evaluate_play(...)
	G.SCORING_COROUTINE = coroutine.create(oldplay)
	G.LAST_SCORING_YIELD = love.timer.getTime()
	G.CARD_CALC_COUNTS = {} -- keys = cards, values = table containing numbers
	local success, err = coroutine.resume(G.SCORING_COROUTINE, ...)
	if not success then
		error(err)
	end
end

local tal_aborted
function G.FUNCS.tal_abort()
	tal_aborted = true
end

local function stopping()
	G.SCORING_COROUTINE = nil
	G.FUNCS.exit_overlay_menu()
	local totalCalcs = 0
	for i, v in pairs(G.CARD_CALC_COUNTS) do
		totalCalcs = totalCalcs + v[1]
	end
	G.GAME.LAST_CALCS = totalCalcs
	G.GAME.LAST_CALC_TIME = G.CURRENT_CALC_TIME
	G.CURRENT_CALC_TIME = 0
	if tal_aborted and Talisman.scoring_state == "main" then
		evaluate_play_final_scoring(text, disp_text, poker_hands, scoring_hand, non_loc_disp_text, percent, percent_delta)
	end
	tal_aborted = nil
	Talisman.scoring_state = nil
end

local function create_UIBox_scoring_text()
	return {
		n = G.UIT.C,
		nodes = {
			{
				n = G.UIT.R,
				config = { padding = 0.1, align = "cm" },
				nodes = {
					{ n = G.UIT.O, config = { object = DynaText({ string = { { ref_table = G.scoring_text, ref_value = 1 } }, colours = { G.C.UI.TEXT_LIGHT }, shadow = true, pop_in = 0, scale = 1, silent = true }) } },
				}
			}, {
				n = G.UIT.R,
				nodes = {
					{ n = G.UIT.O, config = { object = DynaText({ string = { { ref_table = G.scoring_text, ref_value = 2 } }, colours = { G.C.UI.TEXT_LIGHT }, shadow = true, pop_in = 0, scale = 0.4, silent = true }) } },
				}
			}, {
				n = G.UIT.R,
				nodes = {
					{ n = G.UIT.O, config = { object = DynaText({ string = { { ref_table = G.scoring_text, ref_value = 3 } }, colours = { G.C.UI.TEXT_LIGHT }, shadow = true, pop_in = 0, scale = 0.4, silent = true }) } },
				}
			}, {
				n = G.UIT.R,
				nodes = {
					{ n = G.UIT.O, config = { object = DynaText({ string = { { ref_table = G.scoring_text, ref_value = 4 } }, colours = { G.C.UI.TEXT_LIGHT }, shadow = true, pop_in = 0, scale = 0.4, silent = true }) } },
				}
			}, {
				n = G.UIT.R,
				nodes = {
					UIBox_button({
						colour = G.C.BLUE,
						button = "tal_abort",
						label = { localize("talisman_string_E") },
						minw = 4.5,
						focus_args = { snap_to = true },
					})
				}
			},
		}
	}
end

local function create_UIBox_scoring_overlay()
	return {
		n = G.UIT.ROOT,
		config = {
			align = "cm",
			padding = 9999,
			offset = { x = 0, y = -3 },
			r = 0.1,
			colour = { G.C.GREY[1], G.C.GREY[2], G.C.GREY[3], 0.7 }
		},
		nodes = { create_UIBox_scoring_text() }
	}
end

local function overlay()
	G.scoring_text = { localize("talisman_string_D"), "", "", "" }
	G.FUNCS.overlay_menu({
		definition = create_UIBox_scoring_overlay(),
		config = { align = "cm", offset = { x = 0, y = 0 }, major = G.ROOM_ATTACH, bond = 'Weak' }
	})
end

local function upadteText()
	local totalCalcs = 0
	for i, v in pairs(G.CARD_CALC_COUNTS) do
		totalCalcs = totalCalcs + v[1]
	end
	local jokersYetToScore = #G.jokers.cards + #G.play.cards - #G.CARD_CALC_COUNTS
	G.scoring_text[1] = localize("talisman_string_D")
	G.scoring_text[2] = localize("talisman_string_F") .. tostring(totalCalcs) .. " (" .. tostring(number_format(G.CURRENT_CALC_TIME)) .. "s)" G.scoring_text[3] = localize("talisman_string_G") .. tostring(jokersYetToScore)
	G.scoring_text[4] = localize("talisman_string_H") .. tostring(G.GAME.LAST_CALCS or localize("talisman_string_I")) .. " (" .. tostring(G.GAME.LAST_CALC_TIME and number_format(G.GAME.LAST_CALC_TIME) or "???") .. "s)"
end

local oldupd = love.update
function love.update(dt, ...)
	oldupd(dt, ...)
	if not G.SCORING_COROUTINE then return end

	if collectgarbage("count") > 1024 * 1024 then
		collectgarbage("collect")
	end

	if coroutine.status(G.SCORING_COROUTINE) == "dead" or tal_aborted then
		stopping()
		return
	end

	if not G.OVERLAY_MENU then
		overlay()
	else
		G.CURRENT_CALC_TIME = (G.CURRENT_CALC_TIME or 0) + dt
		upadteText()
	end

	--this coroutine allows us to stagger GC cycles through
	--the main source of waste in terms of memory (especially w joker retriggers) is through local variables that become garbage
	--this practically eliminates the memory overhead of scoring
	--event queue overhead seems to not exist if Talismans Disable Scoring Animations is off.
	--event manager has to wait for scoring to finish until it can keep processing events anyways.

	G.LAST_SCORING_YIELD = love.timer.getTime()
	assert(coroutine.resume(G.SCORING_COROUTINE))
end

Talisman.TIME_BETWEEN_SCORING_FRAMES = 0.03
-- 30 fps during scoring
-- we dont want overhead from updates making scoring much slower
-- originally 10 fps, I think 30 fps is a good way to balance it while making it look smooth, too
-- wrap everything in calculating contexts so we can do more things with it
Talisman.calculating_joker = false
Talisman.calculating_score = false
Talisman.calculating_card = false
Talisman.dollar_update = false

local ccj = Card.calculate_joker
function Card:calculate_joker(context)
	--scoring coroutine
	G.CURRENT_SCORING_CARD = self
	G.CARD_CALC_COUNTS = G.CARD_CALC_COUNTS or {}
	if G.CARD_CALC_COUNTS[self] then
		G.CARD_CALC_COUNTS[self][1] = G.CARD_CALC_COUNTS[self][1] + 1
	else
		G.CARD_CALC_COUNTS[self] = { 1, 1 }
	end

	if G.LAST_SCORING_YIELD and ((love.timer.getTime() - G.LAST_SCORING_YIELD) > Talisman.TIME_BETWEEN_SCORING_FRAMES) and coroutine.running() then
		coroutine.yield()
	end
	Talisman.calculating_joker = true
	local ret, trig = ccj(self, context)

	if ret and type(ret) == "table" and ret.repetitions then
		if not ret.card then
			G.CARD_CALC_COUNTS.other = G.CARD_CALC_COUNTS.other or { 1, 1 }
			G.CARD_CALC_COUNTS.other[2] = G.CARD_CALC_COUNTS.other[2] + ret.repetitions
		else
			G.CARD_CALC_COUNTS[ret.card] = G.CARD_CALC_COUNTS[ret.card] or { 1, 1 }
			G.CARD_CALC_COUNTS[ret.card][2] = G.CARD_CALC_COUNTS[ret.card][2] + ret.repetitions
		end
	end
	Talisman.calculating_joker = false
	return ret, trig
end
