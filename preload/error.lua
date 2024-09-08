local errors = {}

function errmsg(ec)
	if not ec then
		return "nil"
	end
	if not errors[ec] then
		return "未知错误"
	end
	return errors[ec].desc
end

local function add(err)
	assert(errors[err.code] == nil, string.format("have the same error code[%x], msg[%s]", err.code, err.desc))
	errors[err.code] = {code = err.code, desc = err.desc}
	return err.code
end

SYSTEM_ERROR = {
	success            = add{code = 0x0000, desc = "请求成功"},
	unknow             = add{code = 0x0001, desc = "未知错误"},
}


return errors