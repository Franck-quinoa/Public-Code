#!/bin/bash

###
# Vars
###

# Old version
OLD_VERSION=$1
# New Version
NEW_VERSION=$2
# Install path
INSTALL_PATH=/var/www
# Name of the Database 4 backup
DB_NAME=nextcloud

###
# Script
###

# Stop WebServer to avoid changes while upgrading
sudo service apache2 stop
# Backup the original nexcloud with the version number for config recall
sudo mv $INSTALL_PATH/nextcloud $INSTALL_PATH/nextcloud_$OLD_VERSION
# Backup the DB to original nexcloud w/ version nb
sudo mysql -u root $DB_NAME | sudo gzip > $INSTALL_PATH/nextcloud_$OLD_VERSION/DB_DUMP_NC_$OLD_VERSION.sql.gz
# Download new version's release from github
wget -O /tmp/nextcloud-$NEW_VERSION.tar.bz2 https://github.com/nextcloud-releases/server/releases/download/v$NEW_VERSION/nextcloud-$NEW_VERSION.tar.bz2
# remove old version's release package (for disk space)
rm -rf /tmp/nextcloud-$OLD_VERSION.tar.bz2
# Unpack to install path and change owner of extracted files
sudo tar -xf /tmp/nextcloud-$NEW_VERSION.tar.bz2 -C $INSTALL_PATH/ && sudo chown -R www-data:www-data $INSTALL_PATH/nextcloud
# Recover config file
sudo cp -a $INSTALL_PATH/nextcloud_$OLD_VERSION/config/config.php $INSTALL_PATH/nextcloud/config/
# Creating apps-external path because it doesn't exist in the extracted release
sudo -u www-data mkdir -p $INSTALL_PATH/nextcloud/apps-external
# Launching the upgrade with apache server's user
sudo -E -u www-data php $INSTALL_PATH/nextcloud/occ upgrade
# some commands to optimize the database
sudo -u www-data php $INSTALL_PATH/nextcloud/occ db:add-missing-indices
sudo -u www-data php $INSTALL_PATH/nextcloud/occ db:add-missing-columns
sudo -u www-data php $INSTALL_PATH/nextcloud/occ db:add-missing-primary-keys
# repair the database can be needed some times
sudo -u www-data php /var/www/nextcloud/occ maintenance:repair --include-expensive
# remove old version's folder
## sudo rm -rf $INSTALL_PATH/nextcloud_$OLD_VERSION
# restarting the apache web server to let people use the new software
sudo service apache2 start
