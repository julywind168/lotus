--
-- 消息(事件) 订阅/推送
--

local M = {}


local listeners = {}


local function event_queue(name)
    listeners[name] = listeners[name] or {}
    return listeners[name]
end


function M.pub(name, ...)
    local queue = event_queue(name)
    for i,cb in ipairs(queue) do
        cb(...)
    end
end


function M.sub(name, callback)
    local queue = event_queue(name)
    table.insert(queue, callback)

    return function ()
        for i,cb in ipairs(queue) do
            if cb == callback then
                return table.remove(queue, i)
            end
        end
    end
end


function M.sub_once(name, callback)
    local unsub; unsub = M.sub(name, function (...)
        unsub()
        callback(...)
    end)
    return unsub
end


function M.sub_many(name, callback, num)
    assert(num >= 1)
    local count = 0
    local unsub; unsub = M.sub(name, function (...)
        count = count + 1
        if count == num then
            unsub()
        end
        callback(...)
    end)
    return unsub
end


return M