# lotus
lua lambda state storage middleware


# C/S model

## Client API
```lua
    local client_schema = {
        typename = "client",
        unique = false,
        init = {},  -- optional
        handlers = {
            ping = [[
            function(ctx, client, params)
                ctx.log("ping")
                -- push msg to channel
                ctx.publish("client-socket-" .. client.id, {name = "pong"})
            end
            ]]
        }
    }
    -- connect to lotus server
    lotus.connect("127.0.0.1", 9999)
    lotus.login("account", "password", "gate")
    lotus.register(client_schema)

    -- init 只会执行一次 (如果 S 中 state 已存在, 则忽略)
    local s = lotus.init(typename, statename, t)

    -- 更新 state, k1 ...  是可选的
    local s = lotus.update(statename, k1, k2, ..., v)

    -- remote exec (warn: no return value)
    s.ping()

-- message - queue
    local channel = lotus.channel(name)
    channel.subscribe(callback)
    channel.publish(msg)
    channel.delete()

    -- lotus.channel("client-socket-100001"):subscribe(callback)

-- socket request (command)
    -- 1. 'register-schema' (schema)
    -- 2. 'init-state' (typename, statename, init_value)
    -- 3. 'update-state' (statename, k1, k2, ..., v)
    -- 4. 'execute-state' (statename, funcname, ...)

    -- 5. 'channel-subscribe'
    -- 6. 'channel-push'

-- socket message from lotus
    -- 1. channel-msg (channel_name, msg)
```

## Server API
```lua
-- ctx:
    -- 日志
    -- ctx.log(...), ctx.warn(...), ctx.error(...)

    -- 销毁 state
    -- ctx.exit()

    -- 初始化一个 state
    -- s = ctx.initstate(typename, statename, value)

    -- 更新某个 state
    -- s = ctx.updatestate(statename, k1, k2, ..., v)

    -- 获得一个 remote state proxy
    -- s = ctx.state(name)

    -- timer:
    -- ctx.timeout(name, time, callback_name)
    -- ctx.interval(name, time, callback_name)
    -- ctx.querytimer(name)
    -- ctx.killtimer(name)

-- state:
    -- s.ping() -- remote call (warn: no return value)

```

## Todo

1. channel 添加缓存, 比如设置频道缓存最近 256 条消息 (用于断线重连等)
```lua
    {{id: 100, msg: "hello"}, {id: 101, msg: "world"}, ...}
```
2. client 可以主动查询频道历史消息
```lua
    -- 查询最后 10 条
    channel-history(channel_name, {last = 10})
    -- 查询从 id = 100 开始的所有消息
    channel-history(channel_name, {from = {id = 100}})
```
3. server 状态的持久化 (mongo or redis)