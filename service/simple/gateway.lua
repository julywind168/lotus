local skynet = require "skynet"
local socket = require "skynet.socket"
local json = require "json"
local db = require "mongo".init("lotus")

local S = {}

local clients = {}      -- client_id -> client

local function auth(account, password)
    if not account or not password then
        return false, "Account or password is nil"
    end
    local u = db:find_one("user", {account = account})
    if not u then
        return false, string.format("Account %s not exist", account)
    end
    if u.password ~= password then
        return false, "Password error"
    end
    return u.project
end

-- name: "PROJECT_NAME.NODE_NAME"
local function new_client(fd)
    local self = {
        fd = fd,
        verified = false
    }

    function self.send(msg)
        if self.fd and socket.write(self.fd, string.pack(">s2", json.encode(msg))) then
            -- pass
        else
            table.insert(self.msgcache, msg)
        end
    end

    function self.close()
        socket.close(fd)
    end

    function self.message(msg)
        if self.verified then
            skynet.send(self.agent, "lua", "client", msg)
        else
            -- auth
            -- todo: handshake (reconnect)
            local project, err = auth(msg.account, msg.password)
            if project then
                local id = ("%s.%s"):format(project, msg.name) -- eg: "game1.gate1"
                local c = clients[id]
                if c then
                    c.close() -- kill old client
                end
                self.verified = true
                self.project = project
                self.name = msg.name
                self.id = id
                self.token = string.random_str(8)
                self.msgcache = c and c.msgcache or {}
                self.agent = c and c.agent or skynet.newservice("simple", "agent", self.project, self.name)
                socket.write(self.fd, ("200 OK (token:%s), welcome to lotus\n"):format(self.token))
                clients[self.id] = self
            else
                socket.write(self.fd, ("401 Unauthorized, %s\n"):format(err))
                self.close()
            end
        end
    end

    function self.disconnect(fd)
        skynet.error("Client disconnect:", fd)
        if fd == self.fd then
            self.fd = nil
        end
    end

    return self
end


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

local function start(port)
    local function accept(fd, addr)
        skynet.error("New client from : "..addr)
        local c = new_client(fd)
        socket.start(fd)
        local last = ""
        while true do
            local pack
            pack, last = recv_package(fd, last)
            if not pack then
                break
            else
                c.message(json.decode(pack))
            end
        end
        c.disconnect(fd)
    end

    local id = socket.listen("0.0.0.0", port)
    skynet.error(string.format("Listen at 0.0.0.0:%s", port))
    socket.start(id, function(fd, addr)
        skynet.fork(accept, fd, addr)
    end)
end

function S.send2client(id, msg)
    local c = clients[id]
    if c then
        c.send(msg)
    else
        skynet.error(("send2client error, client %s not exist"):format(id))
    end
end


skynet.init(function ()
    start(9999)
end)


return S