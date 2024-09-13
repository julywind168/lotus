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
    local s = lotus.init(typename, name, t)

    -- 更新 state, k1 ...  是可选的
    local s = lotus.set(name, k1, k2, ..., v)

    -- remote exec (warn: no return value)
    s.ping()

-- message - queue
    local channel = lotus.channel(name)
    channel.subscribe(callback)
    channel.push(msg)
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
-- 日志: ctx.log, ctx.warn, ctx.error

-- state 销毁: ctx.exit()


```