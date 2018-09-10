#!/bin/sh

me=`basename "$0"`
echo "[i] resty-counter running: $me"

# initialize nginx folder
if [ ! -f /usr/local/openresty/nginx/conf/conf.d/server.conf ]; then
    echo "[i] running for the 1st time"
    rsync --update -raz /usr/local/openresty/nginx/conf-bak/conf.d/* /usr/local/openresty/nginx/conf/conf.d

    # reload to catch new conf
    /usr/local/openresty/bin/openresty -s reload
fi
