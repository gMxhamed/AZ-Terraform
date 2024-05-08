#!/bin/sh
MOUNT_DIR=/srv/www
NFS_ENDPOINT=${nfs_endpoint}
CONTAINER_NAME=${element(split(".",nfs_endpoint),0)}
BLOB_STORAGE_NAME=${blob_storage_name}
WORDPRESS_VERSION=${wordpress_version}

apt update -y && apt upgrade -y

if [ ! -z NFS_ENDPOINT ]; then
    apt install -y nfs-common  \
                apache2 \
                ghostscript \
                libapache2-mod-php \
                mysql-server \
                php \
                php-bcmath \
                php-curl \
                php-imagick \
                php-intl \
                php-json \
                php-mbstring \
                php-mysql \
                php-xml \
                php-zip

    mkdir -p $MOUNT_DIR
    mount.nfs -o sec=sys,vers=3,nolock,proto=tcp $NFS_ENDPOINT:/$CONTAINER_NAME/$BLOB_STORAGE_NAME $MOUNT_DIR
    if [ -z "$(ls -A $MOUNT_DIR)" ];
    then
        wget https://wordpress.org/wordpress-$WORDPRESS_VERSION.tar.gz
        tar -xzf wordpress-$WORDPRESS_VERSION.tar.gz -C $MOUNT_DIR
        chown -R www-data: $MOUNT_DIR
        sudo apt install -y apt-transport-https software-properties-common wget
        sudo mkdir -p /etc/apt/keyrings/
        wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
        echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
        sudo apt-get update
        sudo apt-get install grafana -y
        sudo systemctl daemon-reload
        sudo systemctl start grafana-server
        sudo systemctl enable grafana-server.service
    fi
    cat <<EOF >> /etc/apache2/sites-available/wordpress.conf
<VirtualHost *:80>
    DocumentRoot $MOUNT_DIR/wordpress
    <Directory $MOUNT_DIR/wordpress>
        Options FollowSymLinks
        AllowOverride Limit Options FileInfo
        DirectoryIndex index.php
        Require all granted
    </Directory>
    <Directory $MOUNT_DIR/wordpress/wp-content>
        Options FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>
EOF
    a2ensite wordpress
    a2enmod rewrite
    a2dissite 000-default
    service apache2 reload
    service grafana-server start
    sudo update-rc.d grafana-server defaults
    service grafana-server restart
else
    echo "No NFS endpoint to mount, skipping !"
fi