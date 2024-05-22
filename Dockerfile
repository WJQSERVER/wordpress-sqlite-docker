FROM debian:12.5-slim

VOLUME /data/caddy

# 更新并安装所需的软件包
RUN apt-get update && apt-get install -y \
    sed wget curl vim tar zstd

# 下载和安装 Caddy
RUN mkdir -p /data/caddy/config
RUN wget -O /data/caddy/caddy.tar.gz https://raw.githubusercontent.com/WJQSERVER/tools-stable/main/program/caddy/caddy.tar.gz
RUN tar -xzvf /data/caddy/caddy.tar.gz -C /data/caddy 
RUN rm /data/caddy/caddy.tar.gz 
RUN chmod +x /data/caddy/caddy 
RUN chown www-data:www-data /data/caddy/caddy 
RUN wget -O /data/caddy/Caddyfile https://raw.githubusercontent.com/WJQSERVER/tools-stable/main/web/caddy/Caddyfile

CMD ["/data/caddy/caddy", "run", "--config", "/data/caddy/Caddyfile"]
