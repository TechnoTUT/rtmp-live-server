FROM alqutami/rtmp-hls:latest

# Copy the nginx configuration file
COPY nginx.conf /etc/nginx/nginx.conf

# Copy the players html files
RUN rm -rf /usr/local/nginx/html/players/*
COPY players /usr/local/nginx/html/players