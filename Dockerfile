FROM alqutami/rtmp-hls:latest

# Copy the nginx configuration file
COPY nginx.conf /etc/nginx/nginx.conf

# Copy the players html files
COPY players /usr/local/nginx/html/players