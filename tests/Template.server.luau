--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local spec = require(ReplicatedStorage.DevPackages.spec)

local config = spec.configure({
    pretty = {
        disable_emoji = true,
        disable_unicode = true
    }
})

local function template()
    local describe = config.describe
    local test = config.test
    local expect = config.expect

    describe("Template", function()
        test("its work", function()
            expect(1).is(1)
            expect(1).never_is(2)
        end)
    end)
end

local test = config.collect_tests(template)
config.run_tests(test, {})