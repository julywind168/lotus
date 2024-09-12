local skynet = require "skynet"

local function newproject(name)
    local schemas = {}
    local states = {}
    local self = {}

    local statetype = {}

    function self.register(schema)
        schemas[schema.typename] = schema
    end

    function self.init_state(typename, statename, value)
        if not states[typename] then
            states[typename] = {}
        end
        local schema = assert(schemas[typename], typename)
        if not states[typename][statename] then
            local addr = skynet.newservice("simple", "state")
            skynet.send(addr, "lua", "start", name, statename, schema, value)
            states[typename][statename] = addr
            statetype[statename] = typename
        end
    end

    function self.execute_state(statename, funcname, params)
        local typename = statetype[statename]
        local addr = states[typename][statename]
        if addr then
            skynet.send(addr, "lua", "execute", funcname, params and table.unpack(params) or nil)
        end
    end

    return self
end


local S = {
    projects = {}
}

function S._project(name)
    if not S.projects[name] then
        S.projects[name] = newproject(name)
    end
    return S.projects[name]
end


function S.register(project_name, schema)
    S._project(project_name).register(schema)
end


function S.init_state(project_name, typename, statename, value)
    S._project(project_name).init_state(typename, statename, value)
end


function S.execute_state(project_name, statename, funcname, params)
    S._project(project_name).execute_state(statename, funcname, params)
end


return S