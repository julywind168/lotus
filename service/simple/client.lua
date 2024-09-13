local skynet = require "skynet"
local lotus = require "client.skynet.lotus"

local S = {}

local user_schema = {
    typename = "user",
    init = {},  -- optional
    handlers = {
        chat = [[
        function(ctx, me, msg)
            ctx.log(("%s say: %s"):format(me.id, msg))
        end
        ]]
    }
}



skynet.init(function ()
    skynet.error("Client start")
    lotus.connect("127.0.0.1:9999", {
        account = "test",
        password = "123456",
        name = "gate1"
    })
    lotus.register(user_schema)
    local user001 = lotus.init("user", "user#001", {id = "user#001"})
    user001.chat("hello lotus")
end)


return S