return {
	descriptions = {
		Mod = {
			Talisman = {
                name = "Talisman",
                text = {"Một mod tăng giới hạn điểm của Balatro và bỏ qua hoạt ảnh ghi điểm."},
            },
		}
	},
	test = "j",

	tal_disable_anim = 'Tắt Hoạt Ảnh Ghi Điểm',
    tal_disable_omega = 'Disable OmegaNum (requires restart)', -- not localized yet
    tal_enable_compat = 'Enable type compat', -- not localized yet
    tal_enable_compat_warning = {
        'Warning: Type compat does not work with some mods,', -- not localized yet
        'and instead will cause unexpected crash when enabled.' -- not localized yet
    },
	tal_calculating = 'Đang tính toán...',
	tal_abort = 'Huỷ bỏ',
	tal_elapsed = 'Phép tính đã thực hiện',
    tal_current_state = 'Currently scoring', -- not localized yet
    tal_card_prog = 'Scored card progress', -- not localized yet
    tal_luamem = 'Lua memory', -- not localized yet
	tal_last_elapsed = 'Phép tính tay bài trước đó',
	tal_unknown = 'Không rõ',

	--These don't work out of the box because they would be called too early, find a workaround later?
	talisman_error_A = 'Could not find proper Talisman folder. Please make sure the folder for Talisman is named exactly "Talisman" and not "Talisman-main" or anything else.',
	talisman_error_B = '[Talisman] Error unpacking string: ',
	talisman_error_C = '[Talisman] Error loading string: '
}
