-- 枚举定义

local function enum(t)
	for k,v in pairs(t) do
		t[v] = k
	end
	return t
end


-- SomeType = enum {"A", "B", "C"}
