local cnt = 0
local function hello()
    cnt = cnt + 1
    ngx.say("count:", cnt)
end

local _M = {
    hello = hello
}

return _M
