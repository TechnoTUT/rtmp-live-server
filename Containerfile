FROM debian:12-slim

LABEL maintainer="TechnoTUT <gh@technotut.net>"

EXPOSE 1935
EXPOSE 80

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y && apt-get upgrade -y \
    && apt-get install -y nginx libnginx-mod-rtmp \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && rm -rf /etc/nginx/nginx.conf \
    && rm -rf /var/www/html/favicon.ico \
    && mkdir -p /var/www/html/rtmp

COPY nginx.conf /etc/nginx/nginx.conf
COPY favicon.ico /var/www/html/favicon.ico
COPY stat.xsl /var/www/html/rtmp/stat.xsl

CMD ["nginx", "-g", "daemon off;"]