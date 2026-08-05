--!strict
local Types = require(script.Parent.Types)
local Utils = require(script.Parent.Utils)

local RangeIterator = {}
RangeIterator.__index = RangeIterator

function RangeIterator.__iter<K, V>(self: Types.IteratorPrivate<K, V>): () -> (K?, V?, Types.Cursor<V>?)
	return self:iterate()
end

function RangeIterator.new<K, V>(
	startNode: Types.Node<K, V>?,
	maxKey: K,
	lessFun: (K, K) -> boolean,
	equalFun: (K, K) -> boolean,
	update: { Types.Node<K, V> },
	skiptable: Types.SkiptablePrivate<K, V>
): Types.IteratorPublic<K, V>
	local self = setmetatable({}, RangeIterator) :: Types.IteratorPrivate<K, V>
	self._current = startNode
	self._maxKey = maxKey
	self._lessFun = lessFun
	self._equalFun = equalFun
	self._update = update
	self._skiptable = skiptable
	return self
end

function RangeIterator.hasNext<K, V>(self: Types.IteratorPrivate<K, V>): boolean
	local current = self._current
	if current == nil then
		return false
	end
	return self._lessFun(current.key, self._maxKey) or self._equalFun(current.key, self._maxKey)
end

function RangeIterator.next<K, V>(self: Types.IteratorPrivate<K, V>): (K?, V?, Types.Cursor<V>?)
	if not self:hasNext() then
		return nil, nil, nil
	end

	local node = self._current :: Types.Node<K, V>

	Utils.advancePredecessors(self._update, node, self._lessFun)

	local update = table.clone(self._update)
	local cursor: Types.Cursor<V> = {
		remove = function()
			Utils.removeNode(node, update)
			self._skiptable._size -= 1
		end,
		update = function(value: V)
			node.value = value
		end,
	}

	self._current = node.nexts[1]
	return node.key, node.value, cursor
end

function RangeIterator.iterate<K, V>(self: Types.IteratorPrivate<K, V>): () -> (K?, V?, Types.Cursor<V>?)
	return function()
		if self:hasNext() then
			return self:next()
		end
		return nil, nil, nil
	end
end

return RangeIterator
