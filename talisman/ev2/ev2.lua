local LinkedList = require('talisman.ev2.linkedlist')

--- @alias b.Evm.QueueLinkNode f.LinkedListNode<balatro.Event, b.Evm.QueueLinkNode>
--- @alias b.Evm.QueueLink f.LinkedList<balatro.Event, b.Evm.QueueLinkNode>

--- @class b.Evm.Queue: Object
--- @field all b.Evm.QueueLink
--- @field unblockable b.Evm.QueueLink
--- @field unblockableLinks table<b.Evm.QueueLinkNode, b.Evm.QueueLinkNode>
--- @field paused b.Evm.QueueLink
--- @field pausedLinks table<b.Evm.QueueLinkNode, b.Evm.QueueLinkNode>
local IEVMQueue = Object:extend()
IEVMQueue.count = 0

--- @protected
function IEVMQueue:init()
    self.all = LinkedList()
    self.unblockable = LinkedList()
    self.unblockableLinks = {}
    self.paused = LinkedList()
    self.pausedLinks = {}
end

--- @param event balatro.Event
--- @param front? boolean
function IEVMQueue:add(event, front)
    self.count = self.count + 1
    local node = front and self.all:unshift(event) or self.all:push(event)
    if not event.blockable then
        local unblockNode = front and self.unblockable:unshift(event) or self.unblockable:push(event)
        self.unblockableLinks[node] = unblockNode
        self.unblockableLinks[unblockNode] = node
    end
    if event.created_on_pause then
        local pausedNode = front and self.paused:unshift(event) or self.paused:push(event)
        self.pausedLinks[node] = pausedNode
        self.pausedLinks[pausedNode] = node
    end
end
--- @param node b.Evm.QueueLinkNode
function IEVMQueue:delete(node)
    self.count = self.count - 1
    self.all:detachNode(node)

    local unblockable = self.unblockableLinks[node]
    if unblockable then
        self.unblockable:detachNode(unblockable)
        self.unblockableLinks[node] = nil
        self.unblockableLinks[unblockable] = nil
    end

    local paused = self.pausedLinks[node]
    if paused then
        self.paused:detachNode(paused)
        self.pausedLinks[node] = nil
        self.pausedLinks[paused] = nil
    end
end

--- @type balatro.Event.Result
local result_swap = {
    blocking = false,
    completed = false,
    pause_skip = false,
    time_done = false
}

--- @param node b.Evm.QueueLinkNode
--- @param allnode? b.Evm.QueueLinkNode
function IEVMQueue:handle(node, allnode)
    local ev = node.value

    result_swap.blocking = false
    result_swap.completed = false
    result_swap.time_done = false
    result_swap.pause_skip = false

    ev:handle(result_swap)

    if not result_swap.pause_skip and result_swap.completed and result_swap.time_done then
        self:delete(allnode or node)
    end
end

function IEVMQueue:cycle()
    local unblocked_node = self.unblockable.first
    local node = self.all.first
    while node do
        self:handle(node)
        if unblocked_node and unblocked_node.value == node.value then
            unblocked_node = unblocked_node.next
        end
        node = node.next
        if not result_swap.pause_skip and result_swap.blocking then break end
    end

    while unblocked_node do
        self:handle(unblocked_node, self.unblockableLinks[unblocked_node])
        unblocked_node = unblocked_node.next
    end
end

function IEVMQueue:cycle_paused()
    local node = self.paused.first
    local unpaused = false
    local blocked = false
    while node do
        local nnode = not unpaused and self.pausedLinks[node] or nil
        if not blocked or not node.value.blockable then
            self:handle(node, nnode)
        end
        if not G.SETTINGS.paused and not unpaused then
            unpaused, node = true, nnode
        end
        blocked = blocked or not result_swap.pause_skip and result_swap.blocking
        node = node.next
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
    self.paused:clear()
    self.pausedLinks = {}
    self.count = 0
end

function IEVMQueue:addFrom(list)
    if not list then return end
    for i,v in ipairs(list) do
        self:add(v)
    end
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
function IEVM:get_queue(event)
    local queue = self.queues[event]
    if not queue or not queue.unblockable then
        print("event queues for", event, "is lost")
        local nq = EVMQueue()
        nq:addFrom(queue)
        queue = nq
        self.queues[event] = nq
    end
    return queue
end

--- @param event balatro.Event
--- @param queue? balatro.EventManager.QueueType
--- @param front? boolean
function IEVM:add_event(event, queue, front)
    self:get_queue(queue or 'base'):add(event, front)
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

    self:get_queue(queue):clear()
end

--- @protected
function IEVM:cycle_update()
    for k, queue in pairs(self.queues) do
        local q = self:get_queue(k)
        if G.SETTINGS.paused then
            q:cycle_paused()
        else
            q:cycle()
        end
    end
end

function IEVM:update(dt_real, forced)
    local max_burst, interval =  self.max_burst, self.queue_dt
    if Talisman.scoring_coroutine then
        max_burst = 1
        interval = 1 / 8
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
