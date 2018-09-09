FROM openresty/openresty:alpine-fat
MAINTAINER friends@niiknow.org

COPY rootfs/. /usr/local/openresty/nginx

EXPOSE 80 443

# mount to persist configuration, ssl, and purge cache
VOLUME ["/usr/local/openresty/nginx/conf"]
