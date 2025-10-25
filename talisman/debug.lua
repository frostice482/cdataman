local function find_bigs_low(done, list, obj, stack)
	local is = Big and Big.is(obj)
	if (type(obj) ~= 'table' and not is) or done[obj] then return end
	done[obj] = true

	if is then
		list[table.concat(stack, '.')] = obj
		return
	end

	local i = #stack+1
	for k,v in pairs(obj) do
		stack[i] = tostring(k)
		find_bigs_low(done, list, k, stack)
		find_bigs_low(done, list, v, stack)
	end
	stack[i] = nil
end

function Talisman.find_bigs()
	local list = {}
	local done = {}
	local stack = { '_G' }
	find_bigs_low(done, list, _G, stack)
	return list
end