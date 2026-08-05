--!strict
local Types = require(script.Parent.Types)
local Utils = {}

function Utils.createNode<K, V>(
	key: K,
	value: V,
	nexts: {Types.Node<K ,V>},
	prev: Types.Node<K, V>?
): Types.Node<K, V>
	local node: Types.Node<K, V> = {
		key = key,
		value = value,
		nexts = nexts,
		prev = if prev then setmetatable({prev}, {_mode = "v"}) else {}
	}
	return node
end

function Utils.removeNode<K, V>(
	node: Types.Node<K, V>,
	update: { Types.Node<K, V> }
): ()
	for level = 1, #update do
		if update[level] ~= nil and update[level].nexts[level] == node then
			update[level].nexts[level] = node.nexts[level]
		end
	end

	local successor = node.nexts[1]
	if successor ~= nil then
		local predecessor = if update[1] ~= nil then update[1] else nil
		successor.prev[1] = predecessor
	end
end

function Utils.advancePredecessors<K, V>(
	update: { Types.Node<K, V> },
	targetNode: Types.Node<K, V>,
	lessFun: (K, K) -> boolean
)
	for level = 1, #update do
		while update[level].nexts[level] ~= nil and lessFun(update[level].nexts[level].key, targetNode.key) do
			update[level] = update[level].nexts[level]
		end
	end
end

return Utils