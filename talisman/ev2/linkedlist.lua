--- @class f.LinkedListNode<T, LT>: Object, {
---     value: T;
---     prev?: LT;
---     next?: LT;
---     append: fun(self: self, item: T): LT;
---     appendNode: fun(self: self, node: LT);
---     prepend: fun(self: self, item: T): LT;
---     prependNode: fun(self: self, node: LT);
---     detach: fun(self: self);
--- }
local ILinkNode = Object:extend()

--- @protected
function ILinkNode:init(item)
    self.value = item
end

function ILinkNode:append(item)
    local n = ILinkNode(item)
    self:appendNode(n)
    return n
end

function ILinkNode:prepend(item)
    local n = ILinkNode(item)
    self:prependNode(n)
    return n
end

function ILinkNode:appendNode(n)
    if self.next then
        self.next.prev = n
        n.next = self.next
    end
    n.prev = self
    self.next = n
end

function ILinkNode:prependNode(n)
    if self.prev then
        self.prev.next = n
        n.prev = self.prev
    end
    n.next = self
    self.prev = n
end

function ILinkNode:detach()
    if self.prev then self.prev.next = self.next end
    if self.next then self.next.prev = self.prev end
end

--- @alias f.LinkedListNode.Rec f.LinkedListNode<any, f.LinkedListNode.Rec>

--- @type f.LinkedListNode.Rec | fun(): f.LinkedListNode.Rec
local LinkNode = ILinkNode

--- @class f.LinkedList<T, LT>: Object, {
---     first?: LT;
---     last?: LT;
---     push: fun(self: self, item: T): LT;
---     pushNode: fun(self: self, node: LT);
---     unshift: fun(self: self, item: T): LT;
---     unshiftNode: fun(self: self, node: LT);
---     pop: fun(self: self): T?, LT?;
---     shift: fun(self: self): T?, LT?;
---     sync: fun(self: self);
---     syncHead: fun(self: self);
---     syncTail: fun(self: self);
---     loop: fun(self: self): (fun(): T, LT);
---     each: fun(self: self, func: fun(value: T, node: LT));
---     detachNode: fun(self: self, node: LT);
--- }
local ILinkedList = Object:extend()
ILinkedList.Node = LinkNode

function ILinkedList:push(item)
    local n = ILinkNode(item)
    self:pushNode(n)
    return n
end

function ILinkedList:pushNode(n)
    if not self.last then
        self.last = n
        self.first = n
        return
    end
    self.last:appendNode(n)
    self.last = n
end

function ILinkedList:unshift(item)
    local n = ILinkNode(item)
    self:unshiftNode(n)
    return n
end

function ILinkedList:unshiftNode(n)
    if not self.first then
        self.last = n
        self.first = n
        return
    end
    self.first:prependNode(n)
    self.first = n
end

function ILinkedList:pop()
    if not self.last then return end
    local t = self.last
    self.last:detach()
    self.last = self.last.prev
    if not self.last then self.first = nil end
    return t.value, t
end

function ILinkedList:shift()
    if not self.first then return end
    local t = self.first
    self.first:detach()
    self.first = self.first.next
    if not self.first then self.last = nil end
    return t.value, t
end

function ILinkedList:syncHead()
    if not self.first then return end

    while self.first.prev do self.first = self.first.prev end
    while self.first.next and not self.first.next.prev do self.first = self.first.next end
end

function ILinkedList:syncTail()
    if not self.last then return end

    while self.last.next do self.last = self.last.next end
    while self.last.prev and not self.last.prev.next do self.last = self.last.prev end
end

function ILinkedList:sync()
    self:syncHead()
    self:syncTail()
end

function ILinkedList:loop()
    local cur
    return function ()
        cur = cur and cur.next or self.first
        return cur and cur.value, cur
    end
end

function ILinkedList:each(func)
    local cur = self.first
    while cur do
        func(cur.value, cur)
        cur = cur.next
    end
end

function ILinkedList:detachNode(node)
    if node == self.first then self:shift()
    elseif node == self.last then self:pop()
    else node:detach()
    end
end

function ILinkedList:clear()
    self.first = nil
    self.last = nil
end

--- @alias f.LinkedList.Rec f.LinkedList<any, f.LinkedListNode.Rec>

--- @type f.LinkedList.Rec | fun(): f.LinkedList.Rec
local LinkedList = ILinkedList

return LinkedList
