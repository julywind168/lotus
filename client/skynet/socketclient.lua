local skynet = require "skynet"
local socket = require "skynet.socket"
local json = require "json"

local function unpack_package(text)
    local size = #text
    if size < 2 then
        return nil, text
    end
    local s = text:byte(1) * 256 + text:byte(2)
    if size < s + 2 then
        return nil, text
    end

    return text:sub(3, 2 + s), text:sub(3 + s)
end

local function recv_package(fd, last)
    local result
    result, last = unpack_package(last)
    if result then
        return result, last
    end
    local r = socket.read(fd)
    if not r then
        return nil, last
    end
    if r == "" then
        return nil, "closed"
    end
    return recv_package(fd, last .. r)
end


local M = {
    connected = false
}

function M.init(addr, conf)
    M.ip, M.port = addr:match("(.+):(%d+)")
    M.port = tonumber(M.port)
    M.conf = conf
    if M.connect() then
        M.login()
    end
end

function M.connect()
    local fd = socket.open(M.ip, M.port)
    if fd then
        M.fd = fd
        M.connected = true
        skynet.error("Connect to "..M.ip..":"..M.port)
        return true
    else
        skynet.error("Connect to "..M.ip..":"..M.port.." failed")
        return false
    end
end

function M.login()
    M.send(M.conf)
    local r = socket.readline(M.fd)
    skynet.error("Login result:", r)
    if r:sub(1, 3) == "200" then
        skynet.fork(M.recv_thread)
    end
end

function M.send(msg)
    if M.connected then
        socket.write(M.fd, string.pack(">s2", json.encode(msg)))
    else
        skynet.error("Send failed, not connected")
    end
end

function M.recv_thread()
    skynet.error("Recv thread start")
    local last = ""
    while true do
        local pack
        pack, last = recv_package(M.fd, last)
        if not pack then
            break
        else
            -- todo: handle msg
            skynet.error("lotus socket message >>>>>>>", pack)
        end
    end
    skynet.error("lotus server socket closed")
end


return M