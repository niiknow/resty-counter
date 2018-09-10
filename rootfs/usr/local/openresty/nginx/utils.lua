local redis = require 'resty.redis'
local utils = {}

function utils:logErrorAndExit(err)
   ngx.log(ngx.ERR, err)
   utils:exit()
end

function utils:exit()
  if (ngx.var.arg_redir) then
    return ngx.redirect(ngx.var.arg_redir)
  end
  
  ngx.exec('@empty')
end

function utils:healthcheck() 
  local red  = redis:new()
  local hkey = string.format("%s!%s", tenant, day, key)

  red:set_timeout(3000) -- 3 sec

  local ok, err = red:connect(os.getenv("REDIS_HOST"), 6379)
  -- return error here
  if not ok then
    ngx.log(ngx.ERR, err)
    ngx.exit(ngx.ERROR)
  else
    local ok, err = red:set_keepalive(10000, 1000)
    ngx.say('OK')
  end
end

function utils:lookupCount(tenant, day, key) 
  local red  = redis:new()
  local hkey = string.format("%s!%s", tenant, day, key)

  red:set_timeout(3000) -- 3 sec

  local ok, err = red:connect(os.getenv("REDIS_HOST"), 6379)
  -- return error here
  if not ok then
    ngx.log(ngx.ERR, err)
    ngx.exit(ngx.ERROR)
  end


  -- get today
  local vc, err = red:hget(hkey, key);

  -- return error here
  if not vc or vc == ngx.null then
    vc = 0
  end

  local yesterday = os.date("%d", os.time() - 24*60*60)
  local hkey2 = string.format("%s!%s", tenant, yesterday, key)
  
  -- get yesterday
  local vc2, err = red:hget(hkey2, key);

  -- return error here
  if not vc2 or vc2 == ngx.null then
    vc2 = 0
  end

  -- put it into the connection pool of size 100,
  -- with 10 seconds max idle time
  local ok, err = red:set_keepalive(10000, 1000)
  -- return error here

  return ngx.say(string.format("%s,%s", tostring(vc), tostring(vc2)))
end

function utils:count(tenant, day, key)
  local red  = redis:new()
  local hkey = string.format("%s!%s", tenant, day, key)
  red:set_timeout(3000) -- 3 sec

  local ok, err = red:connect(os.getenv("REDIS_HOST"), 6379)
  if not ok then utils:logErrorAndExit("Error connecting to redis: ".. err) end

  local res, err = red:hincrby(hkey, key, 1)

  if res == 1 then
    -- set expire in 3 days
    red:expireat(hkey, os.time() + 86400*3)
  end

  -- put it into the connection pool of size 1000,
  -- with 10 seconds max idle time
  local ok, err = red:set_keepalive(10000, 1000)

  return res
end

return utils