FROM alqutami/rtmp-hls:latest

RUN rm -rf /etc/nginx/nginx.conf && \
    rm -rf /usr/local/nginx/html/players && \
    rm -rf /usr/local/nginx/html/favicon.ico
COPY nginx.conf /etc/nginx/nginx.conf
COPY players /usr/local/nginx/html/players
COPY favicon.ico /usr/local/nginx/html/favicon.ico
