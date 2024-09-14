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
            ctx.publish("chat-world", {from = me.id, msg = msg})

            -- test timer
            ctx.interval("test_timer", 100, "tick")
        end
        ]]
    },
    callbacks = {
        tick = [[
        function(ctx, me, ti)
            if ti.count < 5 then
                ctx.log(("tick: %d, i will shutdown after %d times"):format(ti.count, 5 - ti.count))
            else
                ctx.log("tick: 5, byebye")
                ctx.killtimer(ti.name)
            end
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

    lotus.channel("chat-world").subscribe(function (msg)
        skynet.error("[chat-world] message: ", table.pretty(msg))
    end)

    local user001 = lotus.init("user", "user#001", {id = "user#001"})
    user001.chat("hello lotus")
end)


return S