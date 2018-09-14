FROM niiknow/openresty:0.2.0
LABEL maintainer="noogen <friends@niiknow.org>"
ENV ALLOWED_DOMAINS='.*' AUTO_SSL_VERSION='0.12.0' REDIS_HOST='redis.local' API_KEY='resty-counter'
RUN printf "Build of resty-counter, date: %s\n"  `date -u +"%Y-%m-%dT%H:%M:%SZ"` >> /etc/BUILDS/zz-resty-counter \
    && apk add --no-cache --virtual runtime \
    bash \
    coreutils \
    curl \
    diffutils \
    grep \
    openssl \
    nano \
    less \
    python \
    py-pip \
    rsync \
    sed \
    && pip install --upgrade pip \
    && pip install awscli \
    && /usr/local/openresty/luajit/bin/luarocks install lua-resty-http \
    && /usr/local/openresty/luajit/bin/luarocks install lua-resty-auto-ssl $LUA_RESTY_AUTO_SSL_VERSION \
    && addgroup -S nginx \
    && mkdir -p /var/cache/nginx \
    && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
    && mkdir -p /usr/local/openresty/nginx/conf/conf.d/ssl \
    && openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
      -subj '/CN=sni-support-required-for-valid-ssl' \
      -keyout /usr/local/openresty/nginx/conf/conf.d/ssl/resty-auto-ssl-fallback.key \
      -out /usr/local/openresty/nginx/conf/conf.d/ssl/resty-auto-ssl-fallback.crt \
    && openssl dhparam -out /usr/local/openresty/nginx/conf/conf.d/ssl/dhparam.pem 2048 \
    && chown -R nginx:nginx /usr/local/openresty/nginx/conf/conf.d/ssl \
    && chown -R nginx:nginx /usr/local/openresty/nginx/logs/ \
    && ln -s /usr/local/openresty/nginx/logs/ /var/log/nginx \
    && apk --purge -v del py-pip \
    && rm -rf /var/cache/apk/* /tmp/*
COPY rootfs/. /
RUN cd /tmp \
    && curl -fSL https://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz -o /tmp/GeoLiteCity.dat.gz \
    && gunzip -f GeoLiteCity.dat.gz \
    && rm -f /usr/local/openresty/nginx/conf/conf.d/GeoLiteCity.dat \
    && mv GeoLiteCity.dat /usr/local/openresty/nginx/conf/conf.d/GeoLiteCity.dat \
    && mkdir -p /usr/local/openresty/nginx/conf-bak \
    && rsync --update -raz /usr/local/openresty/nginx/conf/* /usr/local/openresty/nginx/conf-bak \
    && rm -rf /var/cache/apk/* /tmp/*
EXPOSE 80 443
VOLUME ["/usr/local/openresty/nginx/conf"]
