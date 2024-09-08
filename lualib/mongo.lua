local skynet = require "skynet"
local service = require "skynet.service"


local mongo = {}; mongo.__index = mongo

function mongo:find_one(...)
    return skynet.call(self.service_addr, "lua", "find_one", ...)
end

function mongo:find_many(...)
    return skynet.call(self.service_addr, "lua", "find_many", ...)
end

function mongo:count(...)
    return skynet.call(self.service_addr, "lua", "count", ...)
end

function mongo:sum(...)
    return skynet.call(self.service_addr, "lua", "sum", ...)
end

-- use self.request
function mongo:patch(...)
    return self.request(self.service_addr, "lua", "patch", ...)
end

function mongo:insert_one(...)
    return self.request(self.service_addr, "lua", "insert_one", ...)
end

function mongo:insert_many(...)
    return self.request(self.service_addr, "lua", "insert_many", ...)
end

function mongo:delete_one(...)
    return self.request(self.service_addr, "lua", "delete_one", ...)
end

function mongo:delete_many(...)
    return self.request(self.service_addr, "lua", "delete_many", ...)
end

function mongo:update_one(...)
    return self.request(self.service_addr, "lua", "update_one", ...)
end

function mongo:update_many(...)
    return self.request(self.service_addr, "lua", "update_many", ...)
end

function mongo:create_index(...)
    return self.request(self.service_addr, "lua", "create_index", ...)
end

function mongo:drop_index(...)
    return self.request(self.service_addr, "lua", "drop_index", ...)
end

-- name: game | admin
function mongo.init(name, async)
    local self = {
        name = name,
        request = async and skynet.send or skynet.call,
    }
    skynet.init(function ()
        local mongo_service = function (name)
            local skynet = require "skynet"
            local mongo = require "skynet.db.mongo"
            local conf = require(string.format("config.mongo-%s", name))
            local mongo_init = require(string.format("config.mongo-%s-init", name))

            local client, db

            local function init_indexes()
                for coll, idxs in pairs(mongo_init.indexes) do
                    for i, idx in ipairs(idxs) do
                        db[coll]:createIndex(idx)
                        skynet.error("Mongo create index OK,", coll, table.unpack(dump_tables(idx)))
                    end
                end
            end
            
            local function init()
                client = mongo.client(conf)
                db = client[conf.db_name]
                skynet.error(string.format("connect %s success!", tostring(db)))
                init_indexes()
            end

            local command = {}

            function command.insert_one(coll, doc)
                return db[coll]:safe_insert(doc)
            end
          
            function command.insert_many(coll, docs)
                return db[coll]:safe_batch_insert(docs)
            end
            
            function command.delete_one(coll, query)
                return db[coll]:delete(query, 1)
            end
            
            function command.delete_many(coll, query)
                return db[coll]:delete(query)
            end
            
            function command.find_one(coll, query, projection)
                return db[coll]:findOne(query, projection)
            end
            
            function command.find_many(coll, query, projection, sorter, limit, skip)
                local t = {}
                local it = db[coll]:find(query, projection)
                if not it then
                    return t
                end
            
                if sorter then
                    if #sorter > 0 then
                        it = it:sort(table.unpack(sorter))
                    else
                        it = it:sort(sorter)
                    end
                end
            
                if limit then
                    it:limit(limit)
                    if skip then
                        it:skip(skip)
                    end
                end
            
                while it:hasNext() do
                    table.insert(t, it:next())
                end
            
                return t
            end
            
            function command.update_one(coll, query, update)
                return db[coll]:safe_update(query, update)
            end
            
            function command.update_many(coll, query, update)
                return db[coll]:safe_update(query, update, false, true)
            end
            
            -- Index
            function command.create_index(coll, ...)
                return db[coll]:createIndex(...)
            end
            
            function command.drop_index(coll, ...)
                return db[coll]:dropIndex(...)
            end
            
            -- Ex
            function command.patch(coll, query, patch)
                return db[coll]:safe_update(query, { ["$set"] = patch })
            end
            
            function command.count(coll, query)
                return db[coll]:find(query):count()
            end
            
            function command.sum(coll, query, key)
                local pipeline = {}
                if query then
                    table.insert(pipeline, { ["$match"] = query })
                end
            
                table.insert(pipeline, { ["$group"] = { _id = false, [key] = { ["$sum"] = "$" .. key } } })
            
                local result = db:runCommand("aggregate", coll, "pipeline", pipeline, "cursor", {}, "allowDiskUse", true)
            
                if result and result.ok == 1 then
                    if result.cursor and result.cursor.firstBatch then
                        local r = result.cursor.firstBatch[1]
                        return r and r[key] or 0
                    end
                end
                return 0
            end

            skynet.start(function()
                skynet.dispatch("lua", function(session, source, cmd, ...)
                    local f = command[cmd]
                    skynet.ret(skynet.pack(f(...)))
                end)
                init()
            end)
        end
        self.service_addr = service.new("mongo-" .. name, mongo_service, name)
    end)
    return setmetatable(self, mongo)
end

return mongo