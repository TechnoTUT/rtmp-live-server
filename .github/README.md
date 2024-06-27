# live-server
## About
This repository is a docker-based RTMP server.  
It is based on [alqutami/rtmp-hls](https://hub.docker.com/r/alqutami/rtmp-hls) and [簡単ストリーミング中継サーバの作り方](https://zenn.dev/dropcontrol/articles/821c2a0132afd6). Special thanks for the two projects.
## Usage
### Pulling this repository and starting the container
```bash
git clone https://github.com/TechnoTUT/rtmp-live-server.git
cd rtmp-live-server
docker-compose up -d
```
### Start streaming
Connect to `rtmp://<server-ip-address>/live` with OBS or other streaming software.
Set the stream key to `test` and start streaming.
### Watch the stream
Open `http://<server-ip-address>:8080/players/hls.html` in your browser.