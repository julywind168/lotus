local skynet = require "skynet"
local cs = require "skynet.queue"()

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

    function self.update_state(statename, keys, value)
        local typename = statetype[statename]
        local addr = states[typename][statename]
        if addr then
            skynet.send(addr, "lua", "update", keys, value)
        end
    end

    function self.execute_state(statename, funcname, params)
        local typename = statetype[statename]
        local addr = states[typename][statename]
        if addr then
            skynet.send(addr, "lua", "execute", funcname, params)
        end
    end

    function self.kill_state(statename)
        local typename = statetype[statename]
        local addr = states[typename][statename]
        if addr then
            skynet.send(addr, "lua", "shutdown")
            states[typename][statename] = nil
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
    cs(function ()
        S._project(project_name).init_state(typename, statename, value)
    end)
end

function S.update_state(project_name, statename, keys, value)
    cs(function ()
        S._project(project_name).update_state(statename, keys, value)
    end)
end


function S.execute_state(project_name, statename, funcname, params)
    cs(function ()
        S._project(project_name).execute_state(statename, funcname, params)
    end)
end


function S.kill_state(project_name, statename)
    S._project(project_name).kill_state(statename)
end


return S