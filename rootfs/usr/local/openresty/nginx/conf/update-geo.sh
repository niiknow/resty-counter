#!/bin/bash
#
cd /tmp
rm -f GeoLite*.tar.gz
rm -f GeoLite*.mmdb

mkdir -p /usr/local/openresty/nginx/conf/app
wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz
tar xzf GeoLite2-Country.tar.gz --strip 1
mv -f GeoLite2-Country.mmdb /usr/local/openresty/nginx/conf/app/

wget https://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz
tar xzf GeoLite2-City.tar.gz --strip 1
mv -f GeoLite2-City.mmdb /usr/local/openresty/nginx/conf/app/
