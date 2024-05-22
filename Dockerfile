FROM debian:12.5-slim

# 更新并安装所需的软件包
RUN apt-get update && apt-get install -y \
    php php-cgi php-fpm php-curl php-gd php-mbstring php-xml php-sqlite3 sqlite3 php-mysqli unzip sed wget curl vim git sudo tar zstd

# 下载和安装 Caddy
RUN mkdir -p /data/caddy/config
RUN wget -O /data/caddy/caddy.tar.gz https://raw.githubusercontent.com/WJQSERVER/tools-stable/main/program/caddy/caddy.tar.gz
RUN tar -xzvf /data/caddy/caddy.tar.gz -C /data/caddy 
RUN rm /data/caddy/caddy.tar.gz 
RUN chmod +x /data/caddy/caddy 
RUN chown root:root /data/caddy/caddy 
RUN wget -O /data/caddy/Caddyfile https://raw.githubusercontent.com/WJQSERVER/tools-stable/main/web/wordpress/Caddyfile 
RUN wget -O /data/entrypoint.sh https://raw.githubusercontent.com/WJQSERVER/tools-stable/main/web/wordpress/entrypoint.sh 
RUN chmod 755 /data/entrypoint.sh

# 下载和安装 WordPress
RUN mkdir -p /var/www/html/wordpress
RUN wget -O /var/www/html/wordpress/latest-zh_CN.zip https://cn.wordpress.org/latest-zh_CN.zip
RUN unzip /var/www/html/wordpress/latest-zh_CN.zip -d /var/www/html/wordpress
RUN mv /var/www/html/wordpress/wordpress/* /var/www/html/wordpress
RUN rm -rf latest-zh_CN.zip /var/www/html/wordpress/wordpress

# 下载 wp-config.php 和数据库文件
RUN wget -O /var/www/html/wordpress/wp-config.php https://raw.githubusercontent.com/WJQSERVER/tools-stable/main/web/wordpress/wp-config.php 
RUN mkdir -p /var/www/html/wordpress/wp-content/database 
RUN wget https://raw.githubusercontent.com/WJQSERVER/tools-stable/main/web/wordpress/db.sqlite -P /var/www/html/wordpress/wp-content/database

# 安装 SQLite 插件
RUN mkdir -p /var/www/html/wordpress/wp-content/mu-plugins 
RUN wget -O /var/www/html/wordpress/wp-content/sqlite-database-integration.zip https://downloads.wordpress.org/plugin/sqlite-database-integration.zip 
RUN unzip /var/www/html/wordpress/wp-content/sqlite-database-integration.zip -d /var/www/html/wordpress/wp-content/mu-plugins 
RUN rm -rf /var/www/html/wordpress/wp-content/sqlite-database-integration.zip 
RUN cp /var/www/html/wordpress/wp-content/mu-plugins/db.copy /var/www/html/wordpress/wp-content/db.php 
RUN sed -i "s#{SQLITE_IMPLEMENTATION_FOLDER_PATH}#/var/www/html/wordpress/wp-content/mu-plugins#" /var/www/html/wordpress/wp-content/db.php 
RUN sed -i 's#{SQLITE_PLUGIN}#sqlite-database-integration/load.php#' /var/www/html/wordpress/wp-content/db.php

# 修改数据库设置
RUN sqlite3 "/var/www/html/wordpress/wp-content/database/.ht.sqlite" <<EOF \
    && UPDATE wp_options SET option_value = '$siteurl' WHERE option_name = 'siteurl'; \
    && UPDATE wp_options SET option_value = '$siteurl' WHERE option_name = 'home'; \
    && .quit \
    && EOF

RUN chmod 755 -R /var/www/html/wordpress \
    && chmod 640 /var/www/html/wordpress/wp-content/database/.ht.sqlite \
    && chown www-data:www-data -R /var/www/html/wordpress

RUN cat > /data/caddy/config/wordpress <<EOF \
    && $siteurl { \
        root * /root/data/caddy/pages/demo \
        php_fastcgi unix//run/php/php8.2-fpm.sock { \
            import header_realip \
        } \
        file_server \
        import log \
        import error_page \
        import encode \
    } \
    && EOF



ENTRYPOINT ["/data/entrypoint.sh"]

CMD ["/data/caddy/caddy", "run", "--config", "/data/caddy/Caddyfile", "<<EOF"]
EOF
