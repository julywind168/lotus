local skynet = require "skynet"


local S = {}


function S.start(project, name, schema, value)
    S._project = project
    S._name = name
    S._schema = schema
    S._state = value or schema.init or {}
    skynet.error(("state(%s.%s) start ok"):format(project, name))
    dump(S._state)
end

return S