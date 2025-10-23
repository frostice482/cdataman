--scoring coroutine
local oldplay = G.FUNCS.evaluate_play
function G.FUNCS.evaluate_play(...)
	Talisman.scoring_coroutine = coroutine.create(oldplay)
	Talisman.scoring_yield = love.timer.getTime()

	local success, err = coroutine.resume(Talisman.scoring_coroutine, ...)
	if not success then
		error(err)
	end
end

local tal_aborted
function G.FUNCS.tal_abort()
	tal_aborted = true
end

local function clear_state()
	tal_aborted = nil

	Talisman.scoring_coroutine = nil
	Talisman.scoring_time = 0
	Talisman.scoring_joker_count = 0
	Talisman.scoring_state = nil

	Talisman.scoring_card_prev = nil
	Talisman.scoring_joker_prev = nil

	Talisman.calculating_score = nil
	Talisman.calculating_joker = nil
	Talisman.calculating_card = nil
end

local function stopping()
	G.FUNCS.exit_overlay_menu()

	if tal_aborted and Talisman.scoring_state == "main" then
		evaluate_play_final_scoring(text, disp_text, poker_hands, scoring_hand, non_loc_disp_text, percent, percent_delta)
	end

	G.GAME.LAST_CALCS = Talisman.scoring_joker_count
	G.GAME.LAST_CALC_TIME = Talisman.scoring_time
	clear_state()
end

function Talisman.create_UIBox_scoring_text(texts)
	local nodes = {}

	table.insert(nodes, {
		n = G.UIT.R,
		config = { padding = 0.2, align = "cm" },
		nodes = {
			{ n = G.UIT.T, config = { colour = G.C.WHITE, scale = 1, text = localize("tal_calculating") } },
		}
	})

	for i in ipairs(texts) do
		table.insert(nodes, {
			n = G.UIT.R,
			nodes = {
				{ n = G.UIT.T, config = { colour = G.C.WHITE, scale = 0.4, ref_table = texts, ref_value = i } },
			}
		})
	end

	table.insert(nodes, {
		n = G.UIT.R,
		config = { padding = 0.2, align = "cm" },
		nodes = {
			UIBox_button({
				colour = G.C.BLUE,
				button = "tal_abort",
				label = { localize("tal_abort") },
				minw = 4.5,
				focus_args = { snap_to = true },
			})
		}
	})

	return {
		n = G.UIT.C,
		nodes = nodes
	}
end

function Talisman.create_UIBox_scoring_overlay(texts)
	return {
		n = G.UIT.ROOT,
		config = {
			align = "cm",
			padding = 9999,
			offset = { x = 0, y = -3 },
			r = 0.1,
			colour = { G.C.GREY[1], G.C.GREY[2], G.C.GREY[3], 0.7 }
		},
		nodes = { Talisman.create_UIBox_scoring_text(texts) }
	}
end

function Talisman.scoring_overlay()
	Talisman.scoring_text = {
		"", -- currently calculating
		"", -- card progress
		--"", -- joker progress
		"", -- lua mem
	}
	if G.GAME.LAST_CALCS then
		local text = string.format("%s: %d (%.2fs)", localize("tal_last_elapsed"), G.GAME.LAST_CALCS, G.GAME.LAST_CALC_TIME)
		table.insert(Talisman.scoring_text, text)
	end

	G.FUNCS.overlay_menu({
		definition = Talisman.create_UIBox_scoring_overlay(Talisman.scoring_text),
		config = { align = "cm", offset = { x = 0, y = 0 }, major = G.ROOM_ATTACH, bond = 'Weak' }
	})
end

local function upadte_scoring_text()
	Talisman.scoring_text[1] = string.format("%s: %d (%.2fs)", localize("tal_elapsed"), Talisman.scoring_joker_count, Talisman.scoring_time)

	if Talisman.scoring_card_prev then
		local card = Talisman.scoring_card_prev
		local desc = card.area == G.hand and 'hand' or 'play'
		Talisman.scoring_text[2] = string.format("%s: %d/%d (%s)", localize("tal_card_prog"), card.rank, #card.area.cards, desc or '???')
	else
		Talisman.scoring_text[2] = string.format("%s: -", localize("tal_card_prog"))
	end

	--[[
	if Talisman.scoring_joker_prev then
		local card = Talisman.scoring_joker_prev
		Talisman.scoring_text[3] = string.format("%s: %d/%d", localize("tal_joker_prog"), card.rank, #card.area.cards)
	else
		Talisman.scoring_text[3] = string.format("%s: -", localize("tal_joker_prog"))
	end
	]]

	Talisman.scoring_text[3] = string.format("%s: %.2fMB", localize("tal_luamem"), collectgarbage('count') / 1024)
end

function Talisman.update_scoring(dt)
	if collectgarbage("count") > 1024 * 1024 then
		collectgarbage("collect")
	end

	if coroutine.status(Talisman.scoring_coroutine) == "dead" or tal_aborted then
		stopping()
		return
	end

	if not G.OVERLAY_MENU then
		Talisman.scoring_overlay()
	else
		Talisman.scoring_time = (Talisman.scoring_time or 0) + dt
		upadte_scoring_text()
	end

	--this coroutine allows us to stagger GC cycles through
	--the main source of waste in terms of memory (especially w joker retriggers) is through local variables that become garbage
	--this practically eliminates the memory overhead of scoring
	--event queue overhead seems to not exist if Talismans Disable Scoring Animations is off.
	--event manager has to wait for scoring to finish until it can keep processing events anyways.

	Talisman.scoring_yield = love.timer.getTime()
	assert(coroutine.resume(Talisman.scoring_coroutine))
end

local oldupd = love.update
function love.update(dt, ...)
	if Talisman.scoring_coroutine then Talisman.update_scoring(dt) end
	return oldupd(dt, ...)
end

Talisman.TIME_BETWEEN_SCORING_FRAMES = 0.03
-- 30 fps during scoring
-- we dont want overhead from updates making scoring much slower
-- originally 10 fps, I think 30 fps is a good way to balance it while making it look smooth, too
-- wrap everything in calculating contexts so we can do more things with it

clear_state()

function Talisman.shouldyield()
	return Talisman.scoring_joker_count % 250 == 0
		and Talisman.scoring_yield
		and love.timer.getTime() - Talisman.scoring_yield > Talisman.TIME_BETWEEN_SCORING_FRAMES
		and coroutine.running()
end

function Talisman.yieldjoker()
	Talisman.scoring_joker_count = Talisman.scoring_joker_count + 1
	if Talisman.shouldyield() then
		coroutine.yield()
	end
end

local ec = eval_card
function eval_card(card, ctx)
	if not Talisman.scoring_coroutine then return ec(card, ctx) end

	local iv = Talisman.calculating_card
	Talisman.calculating_card = (iv or 0) + 1
	if not iv then
		if card.area == G.hand or card.area == G.play then
			Talisman.scoring_card_prev = card
		--[[elseif card.area == G.jokers then
			Talisman.scoring_joker_prev = card
		]]
		end
	end

	local ret, a, b = ec(card, ctx)

	Talisman.calculating_card = iv
	return ret, a, b
end

local ccj = Card.calculate_joker
function Card:calculate_joker(context)
	if not Talisman.scoring_coroutine then return ccj(self, context) end
	Talisman.yieldjoker()

	local iv = Talisman.calculating_joker
	Talisman.calculating_joker = (iv or 0) + 1
	--[[if not iv and self.area == G.jokers then
		Talisman.scoring_joker_prev = self
	end]]

	local ret, trig = ccj(self, context)
	Talisman.calculating_joker = iv
	return ret, trig
end
