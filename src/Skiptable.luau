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
	self._head = {
		key = nil :: any,
		value = nil :: any,
		nexts = {},
	}
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

function SkiptableModule.set<K, V>(self: Types.SkiptablePrivate<K, V>, key: K, value: V): ()
	local nodeLevel = randomLevel()
	if nodeLevel > #self._head.nexts then
		for level = #self._head.nexts + 1, nodeLevel do
			self._head.nexts[level] = nil :: any
		end
	end

	local maxLevel = math.max(#self._head.nexts, nodeLevel)
	local update: { Types.Node<K, V> } = table.create(maxLevel) :: any
	local currentNode = self._head

	for level = maxLevel, 1, -1 do
		while currentNode.nexts[level] ~= nil and self._lessFun(currentNode.nexts[level].key, key) do
			currentNode = currentNode.nexts[level]
		end
		update[level] = currentNode
	end

	-- CORRECTION : Si la clé existe déjà, mettre à jour la valeur et ne pas créer de doublon
	local existingNode = if update[1] ~= nil then update[1].nexts[1] else nil
	if existingNode ~= nil and self._equalFun(existingNode.key, key) then
		existingNode.value = value
		return
	end

	local nexts: { Types.Node<K, V> } = table.create(nodeLevel) :: any
	local newNode: Types.Node<K, V> = {
		key = key,
		value = value,
		nexts = nexts,
	}

	for level = 1, nodeLevel do
		local pred = if update[level] ~= nil then update[level] else self._head
		nexts[level] = pred.nexts[level]
		pred.nexts[level] = newNode
	end
end

function SkiptableModule.remove<K, V>(self: Types.SkiptablePrivate<K, V>, key: K): boolean
	local update = self:_getPredecessors(key)
	local targetNode = if update[1] ~= nil then update[1].nexts[1] else nil

	if targetNode ~= nil and self._equalFun(targetNode.key, key) then
		Utils._removeNode(targetNode, update)
		return true
	end

	return false
end

function SkiptableModule.get<K, V>(self: Types.SkiptablePrivate<K, V>, key: K): V?
	local currentNode = self._head
	local levels = #self._head.nexts

	for currentLevel = levels, 1, -1 do
		while currentNode.nexts[currentLevel] ~= nil and self._lessFun(currentNode.nexts[currentLevel].key, key) do
			currentNode = currentNode.nexts[currentLevel]
		end
	end

	local targetNode = currentNode.nexts[1]
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
): { V }
	local startNode = self._head
	local levels = #self._head.nexts

	for currentLevel = levels, 1, -1 do
		while startNode.nexts[currentLevel] ~= nil and self._lessFun(startNode.nexts[currentLevel].key, minKey) do
			startNode = startNode.nexts[currentLevel]
		end
	end

	local currentNode = startNode.nexts[1]
	local results: { V } = {}
	local max = if maxResults ~= nil then maxResults else math.huge

	while currentNode ~= nil and (self._lessFun(currentNode.key, maxKey) or self._equalFun(currentNode.key, maxKey)) do
		table.insert(results, currentNode.value)
		if #results >= max then
			break
		end
		currentNode = currentNode.nexts[1]
	end

	return results
end

function SkiptableModule.iterRange<K, V>(
	self: Types.SkiptablePrivate<K, V>,
	minKey: K,
	maxKey: K
): Types.RangeIteratorPublic<K, V>
	local update = self:_getPredecessors(minKey)
	local startNode = if update[1] ~= nil then update[1].nexts[1] else nil

	return RangeIterator.new(startNode, maxKey, self._lessFun, self._equalFun, self, update)
end

return SkiptableModule