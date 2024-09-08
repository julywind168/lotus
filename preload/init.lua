local skynet = require "skynet"
local pubsub = require "pubsub"

require "preload.dump"
require "preload.error"
require "preload.string"
require "preload.table"
require "preload.enum"


function BITSET(n, i, flag)
	if flag == 0 then
		local m = ~(1<<(i-1))
		return m & n
	else
		assert(flag == 1)
		return (1 << (i-1)) | n
	end
end

function BITGET(n, i)
	return (n >> (i-1) &1)
end


function COMBINE(n, n2)
	return (n<<8) + n2
end

function DIVISION(n)
	return n>>8, n&0xff
end


function COMBINE16(n, n2)
	return (n<<16) + n2
end

function DIVISION16(n)
	return n>>16, n&0xffff
end


function BETWEEN(n, min, max)
	return min <= n and n <= max
end


function ENUM(t)
	for k,v in pairs(t) do
		t[v] = k
	end
	return t
end


local skynet_exit = skynet.exit

function skynet.exit()
	pubsub.pub("service_exit")
	skynet_exit()
end