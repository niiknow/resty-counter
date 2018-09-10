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

function utils:lookupCount(tenant, key) 
  local red      = redis:new()
  red:set_timeout(3000) -- 3 sec

  local ok, err = red:connect("redis.local", 6379)
  -- return error here
  if not ok then
    ngx.log(ngx.ERR, err)
    ngx.exit(ngx.ERROR)
  end

  local vc, err = red:hget(tenant, key);
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

  local ok, err = red:connect("redis.local", 6379)
  if not ok then utils:logErrorAndExit("Error connecting to redis: ".. err) end

  local res, err = red:hincrby(tenant, key, 1)

  if res == 1 then
    -- set expire in 1 day
    red:expireat(tenant, time + 86400)
  end

  -- put it into the connection pool of size 1000,
  -- with 10 seconds max idle time
  local ok, err = red:set_keepalive(10000, 1000)

  return res
end

return utils