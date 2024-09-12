# lotus
lua lambda state storage middleware


# C/S model

## Client API
```lua
    local client_schema = {
        typename = "client",
        init = {},  -- optional
        handlers = {
            ping = [[
            function(ctx, client, params)
                ctx.log "pong"
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
    s:ping()

-- socket command
    -- 1. 'register-schema' (schema)
    -- 2. 'init-state' (typename, statename, init_value)
    -- 3. 'update-state' (statename, k1, k2, ..., v)
    -- 4. 'execute-state' (statename, funcname, ...)
```

## Server API
```lua
-- ctx:
-- 日志 ctx.log, ctx.warn, ctx.error



```