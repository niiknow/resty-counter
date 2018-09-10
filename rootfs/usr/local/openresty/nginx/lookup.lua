local utils     = require '.utils'

if (ngx.var.arg_apikey == os.getenv('API_KEY')) then
	utils:lookupCount(ngx.var.tenant, ngx.var.day, ngx.var.key)
else
	ngx.status = 403
end

