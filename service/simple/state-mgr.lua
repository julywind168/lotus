local skynet = require "skynet"
require "skynet.manager"

local S = {
    projects = {}
}

function S._query_project(name)
    if not S.projects[name] then
        S.projects[name] = {
            schemas = {},
            states = {}
        }
    end
    return S.projects[name]
end


function S.register(project, schema)
    local p = S._query_project(project)
    p.schemas[schema.typename] = schema
end


function S.init_state(project, typename, name, value)
    skynet.error(("init_state %s.%s"):format(project, name))
    local p = S._query_project(project)
    if not p.states[name] then
        local schema = assert(p.schemas[typename], typename)
        local addr = skynet.newservice("simple", "state")
        skynet.name(("%s.%s"):format(project, name), addr)
        skynet.send(addr, "lua", "start", project, name, schema, value)
        p.states[name] = {
            typename = typename,
            addr = addr
        }
    end
end


return S