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
	talisman_vanilla = 'Gốc (e308)',
	talisman_bignum = 'BigNum (ee308)',
	talisman_omeganum = 'OmegaNum',

	tal_feature_select = 'Chọn tính năng để bật:',
	tal_disable_anim = 'Tắt Hoạt Ảnh Ghi Điểm',
	tal_score_limit = 'Giới Hạn Điểm (yêu cầu khởi động lại)',
	tal_calculating = 'Đang tính toán...',
	tal_abort = 'Huỷ bỏ',
	tal_elapsed = 'Phép tính đã thực hiện',
	--tal_remaining = 'Số lá chưa ghi điểm',
	tal_last_elapsed = 'Phép tính tay bài trước đó',
	tal_unknown = 'Không rõ',

	--These don't work out of the box because they would be called too early, find a workaround later?
	talisman_error_A = 'Could not find proper Talisman folder. Please make sure the folder for Talisman is named exactly "Talisman" and not "Talisman-main" or anything else.',
	talisman_error_B = '[Talisman] Error unpacking string: ',
	talisman_error_C = '[Talisman] Error loading string: '
}
