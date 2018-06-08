            local function close_redis(obj)
                if not obj then
                    return
                end
                local pool_max_time = 10000 --ms
                local pool_size = 100
                local ok, err = obj:set_keepalive(pool_max_time, pool_size)
                if not ok then
                    ngx.say("set keep-alive error: ", err)
                end
            end

            local redis = require("resty.redis")
            local red = redis:new()

            red:set_timeout(1000)

            local ip = "127.0.0.1"
            local port = 6379
            local ok, err = red:connect(ip, port)
            if not ok then 
                ngx.say("connect error: ", err)
                close_redis(red)
                return ngx.exit(500)
            end
            --从redis获取（session）帐号名等信息
            local user, passwd, err = red:hmget("user", "username", "password")
            if not user then
                ngx.say("get user error: ", err)
                close_redis(red)
                return ngx.exit(404)
            end
            local uname = nil
            local paswd = nil
            local args = nil
            --从POST中获取信息
            ngx.req.read_body()
            args = ngx.req.get_post_args()
            for k, v in pairs(args) do
                if k == 'pass' then
                    paswd = tostring(v)
                end
                if k == 'name' then
                    uname = tostring(v)
                 end
            end
            if paswd ~= user[2] or uname ~= user[1] then
                close_redis(red)
                ngx.exit(403)
            end
            --local res, err = red:set("baka", "wwww")
            ngx.say("user: ", user[1])
            ngx.say("password: ", user[2])
            
            close_redis(red)
            ngx.exit(200)