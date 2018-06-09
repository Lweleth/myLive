function split_slash(str)
	local set = {}
	local format = "(.-)[\\/]+"
	local last_end = 1
	while 1 do
		local sp, ep, res = str:find(format, last_end)
		if not sp then 
			break
		end
		if res ~= "" then
			table.insert(set, res)
		end
		last_end = ep + 1
	end
	if last_end <= #str then
		table.insert(set, str:sub(last_end))
	end
	-- for k, v in pairs(set) do
	-- 	ngx.log(ngx.ERR, "set:", k, v)
	-- end
	return set
end

local param = split_slash(ngx.var.uri)
-- ensure your uri postion.
-- hard code
local action = param[2]
if #param <= 0 then
	ngx.exit(ngx.HTTP_FORBIDDEN)
end

-- get router address from redis cache
local key = action
ngx.log(ngx.ERR, "action:", key)
local res = ngx.location.capture("/redis", {args = {key = key}})
if res.status ~= 200 then
    ngx.log(ngx.ERR, "redis server returned bad status: ",res.status)	
	ngx.exit(res.status)
end

if not res.body then
	ngx.log(ngx.ERR, "redis returned empty body")
	ndx.exit(500)
end

ngx.log(ngx.ERR, "res.body:", res.body)
local parser = require "redis.parser"
local server, typ = parser.parse_reply(res.body)
if typ ~= parser.BULK_REPLY or not server then
	ngx.log(ngx.ERR, "bad redis response: ", res.body)
	ngx.exit(500)
end

-- set default route
if server == "" then
	server = "127.0.0.1:8888"
end  

server = server.."/api/"..action
if ngx.var.QUERY_STRING ~= nil and ngx.var.QUERY_STRING ~= "" then
    server = server .."&"..ngx.var.QUERY_STRING
end

ngx.var.target = server