FROM debian:13-slim

LABEL maintainer="TechnoTUT <gh@technotut.net>"

EXPOSE 1935
EXPOSE 8080

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y \
    && apt-get install -y nginx libnginx-mod-rtmp ffmpeg vainfo i965-va-driver intel-media-va-driver mesa-va-drivers \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && rm -rf /etc/nginx/nginx.conf \
    && rm -rf /var/www/html/favicon.ico \
    && mkdir -p /var/www/html/rtmp /tmp/thumbnails /tmp/hls \
    && chmod 777 /tmp/thumbnails /tmp/hls

COPY nginx.conf /etc/nginx/nginx.conf
COPY favicon.ico /var/www/html/favicon.ico
COPY stat.xsl /var/www/html/rtmp/stat.xsl
COPY cleanup-stream.sh /usr/local/bin/cleanup-stream.sh
COPY generate-thumbnail.sh /usr/local/bin/generate-thumbnail.sh
RUN chmod +x /usr/local/bin/cleanup-stream.sh /usr/local/bin/generate-thumbnail.sh

CMD ["nginx", "-g", "daemon off;"]
