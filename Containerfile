FROM debian:12 as build

LABEL maintainer="TechnoTUT <gh@technotut.net>"

EXPOSE 1935
EXPOSE 80

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y && apt-get upgrade -y \
    && apt-get install -y nginx \
    git wget tar build-essential libperl-dev libgeoip-dev libgd-dev libpcre3 libpcre3-dev libxml2 libxslt1-dev libxslt1.1 libxslt1-dev gettext-base \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /tmp && cd /tmp && wget https://nginx.org/download/nginx-1.22.1.tar.gz && tar xzf nginx-1.22.1.tar.gz && rm -f nginx-1.22.1.tar.gz \
    && wget https://www.openssl.org/source/openssl-3.5.0.tar.gz && tar xzf openssl-3.5.0.tar.gz && rm -f openssl-3.5.0.tar.gz \
    && git clone https://github.com/TechnoTUT/nginx-rtmp-module.git \
    && cd /tmp/nginx-1.22.1 \
    && ./configure --with-cc-opt='-g -O2 -ffile-prefix-map=/build/nginx-AoTv4W/nginx-1.22.1=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2' \
     --with-ld-opt='-Wl,-z,relro -Wl,-z,now -fPIC' --prefix=/usr/share/nginx --conf-path=/etc/nginx/nginx.conf --http-log-path=/var/log/nginx/access.log --error-log-path=stderr \
     --lock-path=/var/lock/nginx.lock --pid-path=/run/nginx.pid --modules-path=/usr/lib/nginx/modules --http-client-body-temp-path=/var/lib/nginx/body --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
     --http-proxy-temp-path=/var/lib/nginx/proxy --http-scgi-temp-path=/var/lib/nginx/scgi --http-uwsgi-temp-path=/var/lib/nginx/uwsgi --with-compat --with-debug --with-pcre-jit --with-http_ssl_module \
     --with-http_stub_status_module --with-http_realip_module --with-http_auth_request_module --with-http_v2_module --with-http_dav_module --with-http_slice_module --with-threads \
     --with-http_addition_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_secure_link_module \
     --with-http_sub_module --with-mail_ssl_module --with-stream_ssl_module --with-stream_ssl_preread_module --with-stream_realip_module --with-http_geoip_module=dynamic --with-http_image_filter_module=dynamic \
     --with-http_perl_module=dynamic --with-http_xslt_module=dynamic --with-mail=dynamic --with-stream=dynamic --with-stream_geoip_module=dynamic \
     --add-dynamic-module=/tmp/nginx-rtmp-module --with-openssl=/tmp/openssl-3.5.0 \
    && make modules

FROM debian:12-slim
RUN apt-get update -y && apt-get upgrade -y \
    && apt-get install -y nginx gettext-base \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /usr/lib/nginx/modules \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && rm -rf /etc/nginx/nginx.conf \
    && rm -rf /usr/local/nginx/html/* \
    && mkdir -p /mnt/hls

COPY --from=build /tmp/nginx-1.22.1/objs/*.so /usr/lib/nginx/modules
COPY --from=build /tmp/nginx-rtmp-module/stat.xsl /usr/local/nginx/html/stat.xsl
COPY nginx.conf /etc/nginx/nginx.conf
COPY players /usr/local/nginx/html/players
COPY favicon.ico /usr/local/nginx/html/favicon.ico

CMD ["nginx", "-g", "daemon off;"]