--!strict
local Types = require(script.Parent.Types)
local RangeIterator = require(script.Parent.RangeIterator)
local Utils = require(script.Parent.Utils)

local SkiptableModule = {}
SkiptableModule.__index = SkiptableModule

local R = Random.new()

local function randomLevel(): number
	local level = 1
	while R:NextInteger(0, 1) == 1 do
		level += 1
	end
	return level
end

local function baseLessFun(a: any, b: any): boolean
	return a < b
end

function SkiptableModule.new<K, V>(t: { [K]: V }?, lessFun: Types.CompFun<K>?): Types.SkiptablePublic<K, V>
	local actualLess = if lessFun ~= nil then lessFun else baseLessFun

	local self = setmetatable({}, SkiptableModule) :: Types.SkiptablePrivate<K, V>
	self._size = 0
	self._head = Utils.createNode(nil :: any, nil :: any, {}, nil)
	self._lessFun = actualLess
	self._equalFun = function(a: K, b: K): boolean
		return not actualLess(a, b) and not actualLess(b, a)
	end

	if t ~= nil then
		for k, v in t do
			self:set(k, v)
		end
	end

	return self
end

function SkiptableModule._getPredecessors<K, V>(self: Types.SkiptablePrivate<K, V>, key: K): { Types.Node<K, V> }
	local maxLevel = math.max(#self._head.nexts, 1)
	local update: { Types.Node<K, V> } = table.create(maxLevel) :: any
	local currentNode = self._head

	for level = maxLevel, 1, -1 do
		while currentNode.nexts[level] ~= nil and self._lessFun(currentNode.nexts[level].key, key) do
			currentNode = currentNode.nexts[level]
		end
		update[level] = currentNode
	end

	return update
end

function SkiptableModule.count<K, V>(self: Types.SkiptablePrivate<K, V>): number
	return self._size
end

function SkiptableModule.clear<K, V>(self: Types.SkiptablePrivate<K, V>): ()
	self._head.nexts = {}
	self._head.prev = {}
	self._size = 0
end

function SkiptableModule.first<K, V>(self: Types.SkiptablePrivate<K, V>): (K?, V?)
	local firstNode = self._head.nexts[1]
	if firstNode ~= nil then
		return firstNode.key, firstNode.value
	end
	return nil, nil
end

function SkiptableModule.last<K, V>(self: Types.SkiptablePrivate<K, V>): (K?, V?)
	local currentNode = self._head
	local maxLevel = #self._head.nexts
	if maxLevel == 0 then return nil, nil end

	for level = maxLevel, 1, -1 do
		while currentNode.nexts[level] ~= nil do
			currentNode = currentNode.nexts[level]
		end
	end

	if currentNode ~= self._head then
		return currentNode.key, currentNode.value
	end
	return nil, nil
end

function SkiptableModule.set<K, V>(self: Types.SkiptablePrivate<K, V>, key: K, value: V): ()
	local nodeLevel = randomLevel()
	local update = self:_getPredecessors(key)

	local existingNode = if update[1] ~= nil then update[1].nexts[1] else nil
	if existingNode ~= nil and self._equalFun(existingNode.key, key) then
		existingNode.value = value
		return
	end

	local nexts: { Types.Node<K, V> } = table.create(nodeLevel) :: any
	local newNode: Types.Node<K, V> = Utils.createNode(key, value, nexts, nil)

	local predecessor = if update[1] ~= nil then update[1] else self._head
	local successor = predecessor.nexts[1]

	newNode.prev[1] = predecessor

	for level = 1, nodeLevel do
		local pred = if update[level] ~= nil then update[level] else self._head
		nexts[level] = pred.nexts[level]
		pred.nexts[level] = newNode
	end

	if successor ~= nil then
		successor.prev[1] = newNode
	end

	self._size += 1
end

function SkiptableModule.remove<K, V>(self: Types.SkiptablePrivate<K, V>, key: K): boolean
	local update = self:_getPredecessors(key)
	local targetNode = if update[1] ~= nil then update[1].nexts[1] else nil

	if targetNode ~= nil and self._equalFun(targetNode.key, key) then
		Utils.removeNode(targetNode, update)
		self._size -= 1
		return true
	end

	return false
end

function SkiptableModule.iterRange<K, V>(
	self: Types.SkiptablePrivate<K, V>,
	minKey: K,
	maxKey: K
): Types.IteratorPublic<K, V>
	local update = self:_getPredecessors(minKey)
	local startNode = if update[1] ~= nil then update[1].nexts[1] else nil

	return RangeIterator.new(startNode, maxKey, self._lessFun, self._equalFun, update, self)
end

function SkiptableModule.iterAll<K, V>(self: Types.SkiptablePrivate<K, V>): Types.IteratorPublic<K, V>
	local startNode = self._head.nexts[1]
	return RangeIterator.new(startNode, nil :: any, function() return true end, function() return false end, {self._head}, self)
end

function SkiptableModule.__iter<K, V>(self: Types.SkiptablePrivate<K, V>): Types.Generator<K, V>
	local iterator = self:iterAll()
	return iterator:iterate()
end

function SkiptableModule.get<K, V>(self: Types.SkiptablePrivate<K, V>, key: K): V?
	local update = self:_getPredecessors(key)
	local targetNode = if update[1] ~= nil then update[1].nexts[1] else nil

	if targetNode ~= nil and self._equalFun(targetNode.key, key) then
		return targetNode.value
	end

	return nil
end

function SkiptableModule.getRange<K, V>(
	self: Types.SkiptablePrivate<K, V>,
	minKey: K,
	maxKey: K,
	maxResults: number?
): { [K]: V }
	local limit = maxResults or math.huge
	local results: { [K]: V } = {}
	local count = 0

	for k, v, _ in self:iterRange(minKey, maxKey) do
		results[k] = v
		count += 1
		if count >= limit then
			break
		end
	end

	return results
end

function SkiptableModule.__len<K, V>(self: Types.SkiptablePrivate<K, V>)
	return self:count()
end

return SkiptableModule
