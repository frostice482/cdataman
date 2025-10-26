local LinkedList = require('talisman.ev2.linkedlist')

--- @alias b.Evm.QueueLinkNode f.LinkedListNode<balatro.Event, b.Evm.QueueLinkNode>
--- @alias b.Evm.QueueLink f.LinkedList<balatro.Event, b.Evm.QueueLinkNode>

--- @class b.Evm.Queue: Object
--- @field all b.Evm.QueueLink
--- @field unblockable b.Evm.QueueLink
--- @field unblockableLinks table<b.Evm.QueueLinkNode, b.Evm.QueueLinkNode>
local IEVMQueue = Object:extend()
IEVMQueue.count = 0
IEVMQueue.countUnblockable = 0

--- @protected
function IEVMQueue:init()
    self.all = LinkedList()
    self.unblockable = LinkedList()
    self.unblockableLinks = {}
end

--- @param event balatro.Event
--- @param front? boolean
function IEVMQueue:add(event, front)
    self.count = self.count + 1
    local node, unblockNode

    if front then
        node = self.all:unshift(event)
        if not event.blockable then
            unblockNode = self.unblockable:unshift(event)
        end
    else
        node = self.all:push(event)
        if not event.blockable then
            unblockNode = self.unblockable:push(event)
        end
    end

    if not event.blockable then
        self.countUnblockable = self.countUnblockable + 1
        self.unblockableLinks[node] = unblockNode
        self.unblockableLinks[unblockNode] = node
    end
end
--- @param node b.Evm.QueueLinkNode
function IEVMQueue:delete(node)
    self.count = self.count - 1
    self.all:detachNode(node)
    local unblockable = self.unblockableLinks[node]
    if unblockable then
        self.countUnblockable = self.countUnblockable - 1
        self.unblockable:detachNode(unblockable)
        self.unblockableLinks[node] = nil
        self.unblockableLinks[unblockable] = nil
    end
end

function IEVMQueue:clear()
    self.all:each(function (e, node)
        if not e.no_delete then
            self:delete(node)
        end
    end)
end

function IEVMQueue:clearAll()
    self.all:clear()
    self.unblockable:clear()
    self.unblockableLinks = {}
    self.count = 0
    self.countUnblockable = 0
end

--- @type b.Evm.Queue | fun(): b.Evm.Queue
local EVMQueue = IEVMQueue

--- @class b.EventManager: Object
--- @field queues table<balatro.EventManager.QueueType, b.Evm.Queue>
local IEVM = Object:extend()
IEVM.prevTotal = 0
IEVM.queue_dt = 1 / (Talisman.config_file.ev2_interval or 60)
IEVM.max_burst = Talisman.config_file.ev2_burst or 8
IEVM.interp_timers = true
IEVM.lastTime = 0
IEVM.lastTotalTime = 0

--- @type b.EventManager | fun(): b.EventManager
local EVM = IEVM

function IEVM:init()
    self.queues = {
        unlock = EVMQueue(),
        base = EVMQueue(),
        tutorial = EVMQueue(),
        achievement = EVMQueue(),
        other = EVMQueue(),
    }
end

--- @param event balatro.Event
--- @param queue? balatro.EventManager.QueueType
--- @param front? boolean
function IEVM:add_event(event, queue, front)
    self.queues[queue or 'base']:add(event, front)
end

function IEVM:clear_queue(queue, exception)
    if not queue then
        for k, entry in pairs(self.queues) do
            entry:clear()
        end
        return
    end

    if exception then
        for k, entry in pairs(self.queues) do
            if k ~= exception then
                entry:clear()
            end
        end
        return
    end

    self.queues[queue]:clear()
end

--- @type balatro.Event.Result
local result_swap = {
    blocking = false,
    completed = false,
    pause_skip = false,
    time_done = false
}

--- @param queue b.Evm.Queue
--- @param node b.Evm.QueueLinkNode
--- @param isall boolean
local function handle(queue, node, isall)
    local ev = node.value
    --if G.SETTINGS.paused and ev.timer == 'TOTAL' then return end

    result_swap.blocking = false
    result_swap.completed = false
    result_swap.time_done = false
    result_swap.pause_skip = false

    ev:handle(result_swap)

    if not result_swap.pause_skip and result_swap.completed and result_swap.time_done then
        local toRemove = isall and node or queue.unblockableLinks[node]
        queue:delete(toRemove)
    end
end

--- @protected
--- @param queue b.Evm.Queue
function IEVM:cycle_update_queue(queue)
    local unblocked_node = queue.unblockable.first

    local node = queue.all.first
    while node do
        handle(queue, node, true)
        if unblocked_node and unblocked_node.value == node.value then
            unblocked_node = unblocked_node.next
        end
        node = node.next
        if not result_swap.pause_skip and result_swap.blocking then break end
    end

    while unblocked_node do
        handle(queue, unblocked_node, false)
        unblocked_node = unblocked_node.next
    end
end

--- @protected
function IEVM:cycle_update()
    for k, queue in pairs(self.queues) do
        self:cycle_update_queue(queue)
    end
end

function IEVM:update(dt_real, forced)
    local max_burst, interval =  self.max_burst, self.queue_dt
    if Talisman.scoring_coroutine then
        max_burst = 1
        interval = 1 / 10
    elseif G.SETTINGS.paused then
        max_burst = 1
        interval = 1 / 30
    end
    local dt_total = G.TIMERS.TOTAL - self.lastTotalTime
    local buffered_dt = G.TIMERS.REAL - self.lastTime
    local count = math.floor(buffered_dt / interval)
    local count_lim = math.min(max_burst, count)

    if count_lim > 0 and self.interp_timers then
        G.TIMERS.REAL = G.TIMERS.REAL - dt_real
        G.TIMERS.TOTAL = G.TIMERS.TOTAL - dt_total
    end

    for i = 1, count_lim, 1 do
        if self.interp_timers then
            G.TIMERS.REAL = G.TIMERS.REAL + dt_real / count_lim
            G.TIMERS.TOTAL = G.TIMERS.TOTAL + dt_total / count_lim
        end
        self:cycle_update()
    end

    self.lastTime = self.lastTime + count * interval
    self.lastTotalTime = G.TIMERS.TOTAL
end

return EVM
