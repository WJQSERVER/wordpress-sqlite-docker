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
RUN chown www-data:www-data /data/caddy/caddy 
RUN wget -O /data/caddy/Caddyfile https://raw.githubusercontent.com/WJQSERVER/tools-stable/main/web/wordpress/Caddyfile 
RUN wget -O /usr/local/bin/init.sh https://raw.githubusercontent.com/WJQSERVER/tools-stable/main/web/wordpress/init.sh 
RUN chmod 755 /usr/local/bin/init.sh

# 下载和安装 WordPress
RUN mkdir -p /var/www/html/wordpress.d
RUN mkdir -p /var/www/html/wordpress
RUN wget -O /var/www/html/wordpress.d/latest-zh_CN.zip https://cn.wordpress.org/latest-zh_CN.zip
RUN unzip /var/www/html/wordpress.d/latest-zh_CN.zip -d /var/www/html/wordpress
RUN mv /var/www/html/wordpress.d/wordpress/* /var/www/html/wordpress.d
RUN rm -rf latest-zh_CN.zip /var/www/html/wordpress.d/wordpress

# 下载 wp-config.php 和数据库文件
RUN wget -O /var/www/html/wordpress.d/wp-config.php https://raw.githubusercontent.com/WJQSERVER/tools-stable/main/web/wordpress/wp-config.php 
RUN mkdir -p /var/www/html/wordpress.d/wp-content/database 
RUN wget https://raw.githubusercontent.com/WJQSERVER/tools-stable/main/web/wordpress/db.sqlite -P /var/www/html/wordpress.d/wp-content/database
RUN mv /var/www/html/wordpress.d/wp-content/database/db.sqlite /var/www/html/wordpress.d/wp-content/database/.ht.sqlite

# 安装 SQLite 插件
RUN mkdir -p /var/www/html/wordpress.d/wp-content/mu-plugins 
RUN wget -O /var/www/html/wordpress.d/wp-content/sqlite-database-integration.zip https://downloads.wordpress.org/plugin/sqlite-database-integration.zip 
RUN unzip /var/www/html/wordpress.d/wp-content/sqlite-database-integration.zip -d /var/www/html/wordpress/wp-content/mu-plugins 
RUN rm -rf /var/www/html/wordpress.d/wp-content/sqlite-database-integration.zip 
RUN cp /var/www/html/wordpress.d/wp-content/mu-plugins/sqlite-database-integration/db.copy /var/www/html/wordpress/wp-content/db.php 
RUN sed -i "s#{SQLITE_IMPLEMENTATION_FOLDER_PATH}#/var/www/html/wordpress/wp-content/mu-plugins#" /var/www/html/wordpress/wp-content/db.php 
RUN sed -i 's#{SQLITE_PLUGIN}#sqlite-database-integration/load.php#' /var/www/html/wordpress/wp-content/db.php

RUN chmod 755 -R /var/www/html/wordpress.d 
RUN chmod 640 /var/www/html/wordpress.d/wp-content/database/.ht.sqlite 
RUN chown www-data:www-data -R /var/www/html/wordpress.d


CMD ["/usr/local/bin/init.sh"]
