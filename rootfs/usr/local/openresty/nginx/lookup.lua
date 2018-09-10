local utils = require '.utils'
utils:lookupCount(ngx.var.tenant, ngx.var.day, ngx.var.key)
