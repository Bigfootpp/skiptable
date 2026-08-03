--!strict

-- Return either a string or a boolean
return function(): boolean | string
    -- Return an error
	if 1 == 2 then return "1 is equal to 2" end

    -- Test passed
	return true
end