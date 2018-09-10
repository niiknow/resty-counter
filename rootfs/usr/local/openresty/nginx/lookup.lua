local utils     = require '.utils'
local apiKey    = os.getenv('LOOKUP_API_KEY')
local args, err = ngx.req.get_uri_args()

if (args['apiKey'] == apiKey) then
	utils:lookupCount(ngx.var.tenant, ngx.var.day, ngx.var.key)
else
	ngx.status = 403
	ngx.exit(ngx.ERROR)
end

