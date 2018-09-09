# resty-counter
> Simple high-performance hit/impression counter

1. create hourly log files in the format: yyyy-mm-dd-hh-access.log
2. daily aws s3 sync /var/log/nginx/access.log.yyyy-mm-dd s3://bucket-name/year=yyyy/month=mm/day=dd/yyyy-mm-dd-hh_access.log
3. store daily counter into redis
4. lookup daily counter result from redis


/im/tenant/key

hincrby hash={tenant:month} key={key} value
expire {tenant:month} 86400*49
