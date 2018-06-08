-- simple chat with redis
local server = require "resty.websocket.server"
local redis = require "resty.redis"

local uid = nil
local args = nil
--从POST中获取信息
ngx.req.read_body()
args = ngx.req.get_post_args()
for k, v in pairs(args) do
    if k == 'uid' then
        uid = tostring(v)
    end
end

if uid == nil then 
    uid = ""
end

--redis
local channel_name = "chat"..uid
local redis_ip = "127.0.0.1"
local redis_port = 6379

local red = redis:new()
red:set_timeout(5000)
local ok, err = red:connect(redis_ip, redis_port)
if not ok then
    ngx.log(ngx.ERR, "failed to connect redis: ", err)
    return ngx.exit(500)
end

--create connection
local wb, err = server:new{timeout = 5000, max_payload_len = 65535}
if not wb then
    ngx.log(ngx.ERR, "failed to new websocket: ", err)
    return ngx.exit(444)
end

--subscribe
local res, err = red:subscribe(channel_name)
if not res then
    ngx.log(ngx.ERR, "failed to sub redis: ", err)
    wb:send_close()
    return ngx.exit(500)
end

local push = function ()
    -- body
    while true do
        local res, err = red:read_reply()
        if res then
            local item = res[3]
            local bytes, err = wb:send_text(item)
            if not bytes then
                -- better error handling
                 ngx.log(ngx.ERR, "failed to send text: ", err)
                return ngx.exit(444)
            end
        end
    end
end

local forkthread = ngx.thread.spawn(push)


--main loop
while true do

    -- get data
    local data, typ, err = wb:recv_frame()
    if wb.fatal then
        ngx.log(ngx.ERR, "failed to receive frame: ", err)
        return ngx.exit(444)
    end

    if not data then
        local bytes, err = wb:send_ping()
        if not bytes then
          ngx.log(ngx.ERR, "failed to send ping: ", err)
          return ngx.exit(444)
        end
        ngx.log(ngx.ERR, "send ping: ", data)
    elseif typ == "close" then
        break
    elseif typ == "ping" then
        local bytes, err = wb:send_pong()
        if not bytes then
            ngx.log(ngx.ERR, "failed to send pong: ", err)
            return ngx.exit(444)
        end
    elseif typ == "pong" then
        ngx.log(ngx.ERR, "client ponged")
    elseif typ == "text" then
        --send to redis
        local red2 = redis:new()
        red2:set_timeout(1000) -- 1 sec
        local ok, err = red2:connect("127.0.0.1", 6379)
        if not ok then
            ngx.log(ngx.ERR, "failed to connect redis: ", err)
            break
        end
        local res, err = red2:publish(channel_name, data)
        if not res then
            ngx.log(ngx.ERR, "failed to publish redis: ", err)
        end
    end
end

wb:send_close()
ngx.thread.wait(forkthread)
