--!strict
local Types = require(script.Parent.Types)
local Utils = {}

function Utils._removeNode<K, V>(
	node: Types.Node<K, V>,
	update: { Types.Node<K, V> }
): ()
	for level = 1, #update do
		if update[level] ~= nil and update[level].nexts[level] == node then
			update[level].nexts[level] = node.nexts[level]
		end
	end
end

return Utils