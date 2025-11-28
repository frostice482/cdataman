--scoring coroutine

local oldplay = G.FUNCS.evaluate_play
local co = {
	TIME_BETWEEN_SCORING_FRAMES = 0.03
}
Talisman.coroutine = co

function co.create_state()
	return {
		coroutine = coroutine.create(oldplay),
		yield = love.timer.getTime(),
		time = 0,
		calculations = 0
	}
end

function co.initialize_state()
	Talisman.scoring_coroutine = co.create_state()
	G.SCORING_COROUTINE = Talisman.scoring_coroutine
end

function co.resume(...)
	if not Talisman.scoring_coroutine then return end
	Talisman.scoring_coroutine.yield = love.timer.getTime()
	assert(coroutine.resume(Talisman.scoring_coroutine.coroutine, ...))
end

function co.shouldyield()
	return Talisman.scoring_coroutine
		and Talisman.scoring_coroutine.calculations % 250 == 0
		and Talisman.scoring_coroutine.yield
		and love.timer.getTime() - Talisman.scoring_coroutine.yield > co.TIME_BETWEEN_SCORING_FRAMES
		and coroutine.running()
end

function co.clear_state()
	Talisman.scoring_coroutine = nil
	G.SCORING_COROUTINE = nil

	Talisman.calculating_score = nil
	Talisman.calculating_joker = nil
	Talisman.calculating_card = nil
	co.aborted = nil
end

function co.forcestop()
	if not Talisman.scoring_coroutine then return end

	G.FUNCS.exit_overlay_menu()
	if co.aborted and Talisman.scoring_coroutine.state == "main" then
		evaluate_play_final_scoring(text, disp_text, poker_hands, scoring_hand, non_loc_disp_text, percent, percent_delta)
	end
	G.GAME.LAST_CALCS = Talisman.scoring_coroutine.calculations
	G.GAME.LAST_CALC_TIME = Talisman.scoring_coroutine.time
	co.clear_state()
end

function co.create_text_ui(texts)
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

function co.create_overlay_ui(texts)
	return {
		n = G.UIT.ROOT,
		config = {
			align = "cm",
			padding = 9999,
			offset = { x = 0, y = -3 },
			r = 0.1,
			colour = { G.C.GREY[1], G.C.GREY[2], G.C.GREY[3], 0.7 }
		},
		nodes = { co.create_text_ui(texts) }
	}
end

function co.overlay()
	co.scoring_text = {
		"", -- currently calculating
		"", -- card progress
		--"", -- joker progress
		"", -- lua mem
	}
	if G.GAME.LAST_CALCS then
		local text = string.format("%s: %d (%.2fs)", localize("tal_last_elapsed"), G.GAME.LAST_CALCS, G.GAME.LAST_CALC_TIME)
		table.insert(co.scoring_text, text)
	end

	G.FUNCS.overlay_menu({
		definition = co.create_overlay_ui(co.scoring_text),
		config = { align = "cm", offset = { x = 0, y = 0 }, major = G.ROOM_ATTACH, bond = 'Weak' }
	})
end

function co.update_text()
	if not Talisman.scoring_coroutine or not co.scoring_text then return end

	co.scoring_text[1] = string.format("%s: %d (%.2fs)", localize("tal_elapsed"), Talisman.scoring_coroutine.calculations, Talisman.scoring_coroutine.time)

	if Talisman.scoring_coroutine.card then
		local card = Talisman.scoring_coroutine.card
		local desc = card.area == G.hand and 'hand' or 'play'
		co.scoring_text[2] = string.format("%s: %d/%d (%s)", localize("tal_card_prog"), card.rank, #card.area.cards, desc or '???')
	else
		co.scoring_text[2] = string.format("%s: -", localize("tal_card_prog"))
	end

	--[[
	if Talisman.scoring_coroutine.joker then
		local card = Talisman.scoring_coroutine.joker
		Talisman.scoring_text[3] = string.format("%s: %d/%d", localize("tal_joker_prog"), card.rank, #card.area.cards)
	else
		Talisman.scoring_text[3] = string.format("%s: -", localize("tal_joker_prog"))
	end
	]]

	co.scoring_text[3] = string.format("%s: %.2fMB", localize("tal_luamem"), collectgarbage('count') / 1024)
end

function co.update(dt)
	if not Talisman.scoring_coroutine then return end

	if collectgarbage("count") > 1024 * 1024 then
		collectgarbage("collect")
	end

	if coroutine.status(Talisman.scoring_coroutine.coroutine) == "dead" or co.aborted then
		co.forcestop()
		return
	end

	co.resume()

	if not G.OVERLAY_MENU then
		co.overlay()
	else
		Talisman.scoring_coroutine.time = Talisman.scoring_coroutine.time + dt
		co.update_text()
	end
end

function G.FUNCS.evaluate_play(...)
	co.initialize_state()
	co.resume(...)
end

function G.FUNCS.tal_abort()
	co.aborted = true
end

local oldupd = love.update
function love.update(dt, ...)
	if Talisman.scoring_coroutine then co.update(dt) end
	return oldupd(dt, ...)
end

local ec = eval_card
function eval_card(card, ctx)
	if not Talisman.scoring_coroutine then return ec(card, ctx) end

	local iv = Talisman.calculating_card
	Talisman.calculating_card = (iv or 0) + 1
	if not iv then
		if card.area == G.hand or card.area == G.play then
			Talisman.scoring_coroutine.card = card
		--[[elseif card.area == G.jokers then
			Talisman.scoring_coroutine.joker = card
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
	Talisman.scoring_coroutine.calculations = Talisman.scoring_coroutine.calculations + 1
	if co.shouldyield() then coroutine.yield() end

	local iv = Talisman.calculating_joker
	Talisman.calculating_joker = (iv or 0) + 1
	--[[if not iv and self.area == G.jokers then
		Talisman.scoring_coroutine.joker = self
	end]]

	local ret, trig = ccj(self, context)
	Talisman.calculating_joker = iv
	return ret, trig
end
