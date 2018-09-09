local utils = require 'utils'
utils:count(ngx.var.tenant, ngx.var.key)
utils:exit()
