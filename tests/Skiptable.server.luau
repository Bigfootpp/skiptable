--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local spec = require(ReplicatedStorage.DevPackages.spec)
local Types = require(ReplicatedStorage.Packages.Skiptable.Types)
local Skiptable = require(ReplicatedStorage.Packages.Skiptable)

local config = spec.configure({
	pretty = {
		disable_emoji = true,
		disable_unicode = true,
	},
})

local function skiptableTests()
	local describe = config.describe
	local test = config.test
	local expect = config.expect

	describe("Skiptable", function()
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

		local function verifyAll()
			local sortedKeys = getSortedKeys()

			for _, k in sortedKeys do
				expect(skiptable:get(k)).is(refMap[k])
			end

			for _ = 1, 20 do
				local nonKey = random:NextInteger(-500, 2500)
				if refMap[nonKey] == nil then
					expect(skiptable:get(nonKey)).is(nil)
				end
			end

			if #sortedKeys > 0 then
				local minK = sortedKeys[1]
				local maxK = sortedKeys[#sortedKeys]
				local expectedValues: { [number]: string } = {}
				local expectedCount = 0
				for _, k in sortedKeys do
					expectedValues[k] = refMap[k]
					expectedCount += 1
				end

				local actualValues = skiptable:getRange(minK, maxK)
				local actualCount = 0
				for k, v in actualValues do
					actualCount += 1
					expect(v).is(expectedValues[k])
				end
				expect(actualCount).is(expectedCount)
			end
		end

		test("Step 1 - Insertions", function()
			for _ = 1, 200 do
				local key = random:NextInteger(1, 1000)
				local val = "val_" .. tostring(key) .. "_" .. tostring(random:NextInteger(100, 999))
				refMap[key] = val
				skiptable:set(key, val)
			end

			verifyAll()
		end)

		test("Step 2 - Updates", function()
			local sortedKeys = getSortedKeys()
			for i = 1, #sortedKeys, 2 do
				local key = sortedKeys[i]
				local val = "updated_" .. tostring(key)
				refMap[key] = val
				skiptable:set(key, val)
			end

			verifyAll()
		end)

		test("Step 3 - Search Range", function()
			for _ = 1, 15 do
				local minK = random:NextInteger(100, 500)
				local maxK = minK + random:NextInteger(50, 400)

				local expected: { [number]: string } = {}
				local expectedCount = 0
				for _, k in getSortedKeys() do
					if k >= minK and k <= maxK then
						expected[k] = refMap[k]
						expectedCount += 1
					end
				end

				local actual = skiptable:getRange(minK, maxK)
				local actualCount = 0
				for k, v in actual do
					actualCount += 1
					expect(v).is(expected[k])
				end
				expect(actualCount).is(expectedCount)
			end
		end)

		test("Step 4 - Iterator Cursor Ops", function()
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

				expect(v).is(refMap[k])

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

			verifyAll()
		end)

		test("Step 5 - Direct Removals", function()
			for _ = 1, 40 do
				local currentKeys = getSortedKeys()
				if #currentKeys == 0 then
					break
				end

				local removeIndex = random:NextInteger(1, #currentKeys)
				local targetKey = currentKeys[removeIndex]

				local removed = skiptable:remove(targetKey)
				expect(removed).is(true)

				refMap[targetKey] = nil
			end

			for _ = 1, 10 do
				local nonKey = random:NextInteger(3000, 4000)
				local removed = skiptable:remove(nonKey)
				expect(removed).is(false)
			end

			verifyAll()
		end)
	end)
end

local test = config.collect_tests(skiptableTests)
config.run_tests(test, {})