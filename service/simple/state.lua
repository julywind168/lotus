local skynet = require "skynet"

local S = {}

local ctx = {}

function ctx.log(...)
    skynet.error(...)
end

function ctx.warn(...)
    skynet.error(...)
end

function ctx.error(...)
    skynet.error(...)
end

function ctx.exit()
    skynet.send("state-mgr", "lua", "kill_state", S._project, S._name)
end


local handlers = {}

local function load_schema(schema)
    for name, code in pairs(schema.handlers) do
        local f = load("return " .. code)
        if f then
            handlers[name] = f()
        else
            error(("load handler failed: %s"):format(name))
        end
    end
end

function S.execute(funcname, params)
    local f = handlers[funcname]
    if f then
        f(ctx, S._state, table.unpack(params))
    else
        skynet.error(("unknown handler: %s"):format(funcname))
    end
end

function S.start(project, name, schema, value)
    S._project = project
    S._name = name
    S._schema = schema
    S._state = value or schema.init or {}
    load_schema(schema)
    skynet.error(("[state: %s.%s] started"):format(project, name))
    dump(S._state)
end

function S.shutdown()
    skynet.exit()
end


return S