FROM oraclelinux:9

ARG nginx_version=1.26.2
ARG rtmp_version=1.2.2

RUN dnf update -y \
    && dnf install -y wget gcc make pcre-devel openssl-devel zlib-devel \
    && dnf clean all \
    && mkdir -p /build \
    && cd /build \
    && wget https://nginx.org/download/nginx-${nginx_version}.tar.gz \
    && tar -xvf nginx-${nginx_version}.tar.gz \
    && rm -f nginx-${nginx_version}.tar.gz \
    && wget https://github.com/arut/nginx-rtmp-module/archive/refs/tags/v${rtmp_version}.tar.gz \
    && tar -xvf v${rtmp_version}.tar.gz \
    && rm -f v${rtmp_version}.tar.gz \
    && cd nginx-${nginx_version} \
    && ./configure \
        --sbin-path=/usr/local/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \		
        --pid-path=/var/run/nginx/nginx.pid \
        --lock-path=/var/lock/nginx.lock \
        --http-client-body-temp-path=/tmp/nginx-client-body \
        --with-http_ssl_module \
        --with-threads \
        --add-module=../nginx-rtmp-module-${rtmp_version} \
    && make -j$(nproc) \
    && make install \
    && cp ../nginx-rtmp-module-${rtmp_version}/stat.xsl /usr/local/nginx/html/ \
    && useradd -r nginx \
    && mkdir -p /var/cache/nginx \
    && chown -R nginx:nginx /var/cache/nginx \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

COPY nginx.conf /etc/nginx/nginx.conf
COPY players /usr/local/nginx/html/players

CMD ["nginx", "-g", "daemon off;"]
