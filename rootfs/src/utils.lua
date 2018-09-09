local redis = require 'resty.redis'
local utils = {}

function utils:logErrorAndExit(err)
   ngx.log(ngx.ERR, err)
   utils:exit()
end

function utils:exit()
  if (ngx.var.redir) then
    return ngx.redirect(ngx.var.redir)
  end
  
  ngx.exec('@empty')
end

function utils:buildKey(tenant)
  local time     = os.time()
  local daysLeft = 32 - os.date("%c")
  local month    = os.date("%m")
  return string.format("%s!%s", tenant, month)
end

function utils:lookupCount(tenant, key) 
  local red      = redis:new()
  red:set_timeout(3000) -- 3 sec

  local ok, err = red:connect("redis", 6379)
  -- return error here
  if not ok then
    ngx.log(ngx.ERR, err)
    ngx.exit(ngx.ERROR)
  end

  local hkey = utils:buildKey(tenant)
  local vc, err = red:hget(hkey, key);
  -- return error here
  if not vc then
    ngx.log(ngx.ERR, err)
    ngx.exit(ngx.ERROR)
  end

  -- put it into the connection pool of size 100,
  -- with 10 seconds max idle time
  local ok, err = red:set_keepalive(10000, 1000)
  -- return error here

  return ngx.say(vc)
end

function utils:count(tenant, key)
  local red = redis:new()
  red:set_timeout(3000) -- 3 sec

  local ok, err = red:connect("redis", 6379)
  if not ok then utils:logErrorAndExit("Error connecting to redis: ".. err) end

  local hkey = utils:buildKey(tenant)
  local res, err = red:hincrby(hkey, key)

  if res == 1 then
    -- set expire in 31 days
    red:expireat(hkey, time + 86400 * daysLeft)
  end

  -- put it into the connection pool of size 1000,
  -- with 10 seconds max idle time
  local ok, err = red:set_keepalive(10000, 1000)

  return res
end

return utils