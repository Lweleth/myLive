local mysql = require "resty.mysql"
local db, err = mysql:new()
if not db then
    ngx.log(ngx.ERR,"failed to instantiate mysql: ", err)
    return ngx.exit(500)
end
db:set_timeout(1000) -- 1 sec
local ok, err, errno, sqlstate = db:connect{
    host = "127.0.0.1",
    port = 3306,
    database = "MyLiveSite",
    user = "LiveAdmin",
    password = "admin",
    max_packet_size = 1024 * 1024 
}

-- or connect to a unix domain socket file listened
-- by a mysql server:
-- local ok, err, errcode, sqlstate =
--       db:connect{
--          path = "/var/run/mysqld/mysqld.sock",
--          port = "3306",
--          database = "MyLiveSite",
--          user = "root",
--          password = "root" 
-- }
if not ok then
    ngx.log(ngx.ERR, "failed to connect: ", err, ": ", errno, " ", sqlstate)
    return ngx.exit(500)
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
    if k == 'uname' then
        uname = tostring(v)
    end
end
--escape param
uname = ngx.quote_sql_str(uname)
paswd = ngx.quote_sql_str(paswd)
local res, err, errcode, sqlstate =
    db:query([[select * from Live_user_info where username=]]..uname..[[and password=]]..paswd)
if not res then
    ngx.log(ngx.ERR,"bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
    return ngx.exit(500)
end

local cjson = require "cjson"

if cjson.encode(res) == [[{}]] then
    -- ngx.log(ngx.ERR, "unknow user:",cjson.encode(res))
    return ngx.exit(404)
end

ngx.exit(200)
