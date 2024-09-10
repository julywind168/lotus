local skynet = require "skynet"

local S = {}


function S.client(msg)
    skynet.error("client message:", table.pretty(msg))
end


return S