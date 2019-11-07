local redis = require 'resty.redis'
local utils = {}

function utils:is_redis_null( res )
    if type(res) == "table" then
        for k,v in pairs(res) do
            if v ~= ngx.null then
                return false
            end
        end
        return true
    elseif res == ngx.null then
        return true
    elseif res == nil then
        return true
    end

    return false
end

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
  local auth  = os.getenv('REDIS_AUTH')
  local red   = redis:new()
  local hkey  = string.format("%s!%s", tenant, day, key)
  local yest  = os.date("%d", os.time() - 24*60*60)
  local hkey2 = string.format("%s!%s", tenant, yest)
  local v1    = 0
  local v2    = 0

  red:set_timeout(3000) -- 3 sec

  local ok, err = red:connect(os.getenv("REDIS_HOST"), 6379)
  -- return error here
  if not ok then
    ngx.log(ngx.ERR, err)
    ngx.exit(ngx.ERROR)
  end

  if not (auth == '') then
    local res, err = red:auth(auth)
    if not res then
      ngx.log(ngx.ERR, err)
      ngx.exit(ngx.ERROR)
    end
  end

  red:init_pipeline()
  red:hget(hkey, key)
  red:hget(hkey2, key)

  local results, err = red:commit_pipeline()
  if results then
    if not utils:is_redis_null(results[1]) then
      v1 = results[1]
    end
    if not utils:is_redis_null(results[2]) then
      v2 = results[2]
    end
  end

  -- put it into the connection pool of size 100,
  -- with 10 seconds max idle time
  red:set_keepalive(10000, 1000)

  return ngx.say(string.format("%s+%s", tostring(v1), tostring(v2)))
end

function utils:count(tenant, day, key, val)
  local keyx = tonumber(os.getenv("REDIS_EXIRE_DAYS") or "3")
  local auth = os.getenv('REDIS_AUTH')
  local red  = redis:new()
  local hkey = string.format("%s!%s", tenant, day)
  local inc  = tonumber(val)

  red:set_timeout(3000) -- 3 seconds

  local ok, err = red:connect(os.getenv("REDIS_HOST"), 6379)

  if not ok then 
    return utils:logErrorAndExit("Error connecting to redis: ".. err) 
  end

  if not (auth == '') then
    local res, err = red:auth(auth)
    if not res then
      return utils:logErrorAndExit("Error authenticating with redis: ".. err) 
    end
  end

  red:init_pipeline();
  red:hincrby(hkey, key, inc or 1)

  -- must not want to expire if more than 9999 days
  if (keyx < 9999) then
    red:expireat(hkey, os.time() + 86400*keyx)
  end

  red:commit_pipeline()

  -- put it into the connection pool of size 1000,
  -- with 10 seconds max idle time
  red:set_keepalive(10000, 1000)
end

return utils