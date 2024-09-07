local skynet = require "skynet"

local name = ...
local S = require("service.simple."..name)


skynet.start(function ()
    skynet.dispatch("lua", function(_,_, cmd, ...)
        local f = assert(S[cmd], cmd)
        skynet.ret(skynet.pack(f(...)))
    end)
end)