local skynet = require "skynet"
local pubsub = require "pubsub"

local args = {...}
local S = require("service.simple." .. args[1])


skynet.start(function ()
    skynet.dispatch("lua", function(_,_, cmd, ...)
        local f = assert(S[cmd], cmd)
        skynet.ret(skynet.pack(f(...)))
    end)

    pubsub.pub("_init", table.unpack(args, 2))
end)