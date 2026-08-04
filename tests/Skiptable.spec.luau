--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function(): boolean | string
local Types = require(ReplicatedStorage.Packages.Skiptable.Types)
	local Skiptable = require(script.Parent.Parent.Packages.Skiptable)

	local function assertEquals(actual: unknown, expected: unknown, message: string): boolean | string
		if actual ~= expected then
			return message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual)
		end
		return true
	end

	local function assertArrayEquals(actual: { string }, expected: { string }, message: string): boolean | string
		if #actual ~= #expected then
			return message .. ": expected length " .. tostring(#expected) .. ", got " .. tostring(#actual)
		end

		for i = 1, #expected do
			if actual[i] ~= expected[i] then
				return message .. ": expected element " .. tostring(i) .. " to be " .. tostring(expected[i]) .. ", got " .. tostring(actual[i])
			end
		end

		return true
	end

	local refMap: { [number]: string } = {}
	local skiptable = Skiptable.new() :: Types.SkiptablePublic<number, string>

	local random = Random.new(12345)

	local function getSortedKeys(): { number }
		local keys: { number } = {}
		for k in refMap do
			table.insert(keys, k)
		end
		table.sort(keys)
		return keys
	end

	local function verifyAll(stepName: string): boolean | string
		local sortedKeys = getSortedKeys()

		for _, k in sortedKeys do
			local res = assertEquals(skiptable:get(k), refMap[k], stepName .. " - search(" .. tostring(k) .. ")")
			if res ~= true then
				return res
			end
		end

		for _ = 1, 20 do
			local nonKey = random:NextInteger(-500, 2500)
			if refMap[nonKey] == nil then
				local res = assertEquals(skiptable:get(nonKey), nil, stepName .. " - search non-existent (" .. tostring(nonKey) .. ")")
				if res ~= true then
					return res
				end
			end
		end

		if #sortedKeys > 0 then
			local minK = sortedKeys[1]
			local maxK = sortedKeys[#sortedKeys]
			local expectedValues: { string } = {}
			for _, k in sortedKeys do
				table.insert(expectedValues, refMap[k])
			end

			local actualValues = skiptable:getRange(minK, maxK)
			local res = assertArrayEquals(actualValues, expectedValues, stepName .. " - full searchRange(" .. tostring(minK) .. ", " .. tostring(maxK) .. ")")
			if res ~= true then
				return res
			end
		end

		return true
	end

	for _ = 1, 200 do
		local key = random:NextInteger(1, 1000)
		local val = "val_" .. tostring(key) .. "_" .. tostring(random:NextInteger(100, 999))
		refMap[key] = val
		skiptable:set(key, val)
	end

	do
		local res = verifyAll("Step 1 (Insertions)")
		if res ~= true then return res end
	end

	local sortedKeys = getSortedKeys()
	for i = 1, #sortedKeys, 2 do
		local key = sortedKeys[i]
		local val = "updated_" .. tostring(key)
		refMap[key] = val
		skiptable:set(key, val)
	end

	do
		local res = verifyAll("Step 2 (Updates)")
		if res ~= true then return res end
	end

	for _ = 1, 15 do
		local minK = random:NextInteger(100, 500)
		local maxK = minK + random:NextInteger(50, 400)

		local expected: { string } = {}
		for _, k in getSortedKeys() do
			if k >= minK and k <= maxK then
				table.insert(expected, refMap[k])
			end
		end

		local actual = skiptable:getRange(minK, maxK)
		local res = assertArrayEquals(actual, expected, "Step 3 - searchRange(" .. tostring(minK) .. ", " .. tostring(maxK) .. ")")
		if res ~= true then return res end
	end

	do
		local minK = 200
		local maxK = 800
		local iterator = skiptable:iterRange(minK, maxK)

		local toRemove: { number } = {}
		local toUpdate: { [number]: string } = {}

		while iterator:hasNext() do
			local k, v, cursor = iterator:next()
			if k == nil or v == nil or cursor == nil then
				break
			end

			local res = assertEquals(v, refMap[k], "Step 4 - iterRange element " .. tostring(k))
			if res ~= true then return res end

			if k % 2 == 0 then
				cursor.remove()
				table.insert(toRemove, k)
			elseif k % 3 == 0 then
				local newVal = "iter_updated_" .. tostring(k)
				cursor.update(newVal)
				toUpdate[k] = newVal
			end
		end

		for _, k in toRemove do
			refMap[k] = nil
		end
		for k, newVal in toUpdate do
			refMap[k] = newVal
		end

		local res = verifyAll("Step 4 (Iterator Cursor Ops)")
		if res ~= true then return res end
	end

	for _ = 1, 40 do
		local currentKeys = getSortedKeys()
		if #currentKeys == 0 then break end

		local removeIndex = random:NextInteger(1, #currentKeys)
		local targetKey = currentKeys[removeIndex]

		local removed = skiptable:remove(targetKey)
		local res = assertEquals(removed, true, "Step 5 - remove(" .. tostring(targetKey) .. ") should return true")
		if res ~= true then return res end

		refMap[targetKey] = nil
	end

	for _ = 1, 10 do
		local nonKey = random:NextInteger(3000, 4000)
		local removed = skiptable:remove(nonKey)
		local res = assertEquals(removed, false, "Step 5 - remove non-existent (" .. tostring(nonKey) .. ") should return false")
		if res ~= true then return res end
	end

	do
		local res = verifyAll("Step 5 (Direct Removals)")
		if res ~= true then return res end
	end

	return true
end