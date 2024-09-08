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
                return "pong"
            end
            ]],
            echo = [[
            function(ctx, client, params)
                return params
            end
            ]]
        }
    }
    -- connect to lotus server
    lotus.connect("127.0.0.1", 9999)
    lotus.register(client_schema)

    -- init 只会执行一次 (如果 S 中 state 已存在, 则忽略)
    local s = lotus.init(typename, name, t)

    -- 更新 state, k1 ...  是可选的
    local s = lotus.set(name, k1, k2, ..., v)

    -- rpc
    local pong = s:ping() -- pong == "pong"


```