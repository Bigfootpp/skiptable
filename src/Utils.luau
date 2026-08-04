--!strict
local Types = require(script.Parent.Types)
local Utils = {}

function Utils.removeNode<K, V>(
	node: Types.Node<K, V>,
	update: { Types.Node<K, V> }
): ()
	for level = 1, #update do
		if update[level] ~= nil and update[level].nexts[level] == node then
			update[level].nexts[level] = node.nexts[level]
		end
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