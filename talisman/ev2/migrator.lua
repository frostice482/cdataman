local ev2 = require("talisman.ev2.ev2")

local Migrator = {
	vanilla = G.E_MANAGER,
	ev2 = ev2(),
	migrated = false
}

function Migrator:tov2()
	if self.migrated then return end
	self.migrated = true

	for k, list in pairs(self.vanilla.queues) do
		for i, event in ipairs(list) do
			self.ev2.queues[k]:add(event)
		end
		self.vanilla.queues[k] = {}
	end
	G.E_MANAGER = self.ev2
end

function Migrator:tovanilla()
	if not self.migrated then return end
	self.migrated = false

	for k, list in pairs(self.ev2.queues) do
		local targetList = self.vanilla.queues[k]
		list.all:each(function (value, node) table.insert(targetList, value) end)
		list:clearAll()
	end
	G.E_MANAGER = self.vanilla
end

return Migrator