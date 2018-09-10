FROM niiknow/openresty:0.1.9

LABEL maintainer="noogen <friends@niiknow.org>"

# allowed domains should be lua match pattern
# example: ^(example.com|example.net)$
ENV ALLOWED_DOMAINS='.*' AUTO_SSL_VERSION='0.12.0' REDIS_HOST='redis.local' LOOKUP_API_KEY='resty-counter'

RUN \
  # Make info file about this build
    printf "Build of resty-counter, date: %s\n"  `date -u +"%Y-%m-%dT%H:%M:%SZ"` >> /etc/BUILDS/zz-resty-counter && \

  # begin
    apk add --no-cache --virtual runtime \
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
    sed && \
    pip install --upgrade pip && \
    pip install awscli && \

  # Even though we install full pkill (via the procps package, which we do for
  # "-U" support in our tests), the /usr/bin version that symlinks BusyBox's
  # more limited pkill version takes precedence. So manually remove this
  # BusyBox symlink to the full pkill version is used.
    if [ -L /usr/bin/pkill ]; then rm /usr/bin/pkill; fi && \

    /usr/local/openresty/luajit/bin/luarocks install lua-resty-http && \
    /usr/local/openresty/luajit/bin/luarocks install lua-resty-auto-ssl $LUA_RESTY_AUTO_SSL_VERSION && \

    addgroup -S nginx && \
    adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx && \
    mkdir -p /usr/local/openresty/nginx/conf/conf.d/ssl && \
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
      -subj '/CN=sni-support-required-for-valid-ssl' \
      -keyout /usr/local/openresty/nginx/conf/conf.d/ssl/resty-auto-ssl-fallback.key \
      -out /usr/local/openresty/nginx/conf/conf.d/ssl/resty-auto-ssl-fallback.crt && \

    openssl dhparam -out /usr/local/openresty/nginx/conf/conf.d/ssl/dhparam.pem 2048 && \
    chown -R nginx:nginx /usr/local/openresty/nginx/conf/conf.d/ssl && \
    chown -R nginx:nginx /usr/local/openresty/nginx/logs/ && \

  # link for ease of refs in conf file
    ln -s /usr/local/openresty/nginx/logs/ /var/log/nginx && \

    apk --purge -v del py-pip && \

    rm -rf /var/cache/apk/*

COPY rootfs/. /

RUN \
  # backup the conf folder 
    cd /tmp && \
    curl -fSL https://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz -o /tmp/GeoLiteCity.dat.gz && \
    gunzip -f GeoLiteCity.dat.gz && \
    rm -f /usr/local/openresty/nginx/conf/conf.d/GeoLiteCity.dat && \
    mv GeoLiteCity.dat /usr/local/openresty/nginx/conf/conf.d/GeoLiteCity.dat && \
    mkdir -p /usr/local/openresty/nginx/conf-bak && \
    rsync --update -raz /usr/local/openresty/nginx/conf/* /usr/local/openresty/nginx/conf-bak

EXPOSE 80 443

# mount to persist configuration, ssl, and purge cache
VOLUME ["/usr/local/openresty/nginx/conf"]