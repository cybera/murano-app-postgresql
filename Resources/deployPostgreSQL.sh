#!/bin/bash

vol=$(sudo readlink -e /dev/disk/by-uuid/$(sudo lsblk -o name,type,mountpoint,label,uuid | grep -v root | grep -v     ephem | grep -v SWAP | grep -v vda | tail -1 | awk '{print $3}'))

sudo mkfs -t ext3 $vol
sudo mkdir /opt/postgresql_data
sudo mount $vol /opt/postgresql_data
echo "$vol /opt/postgresql_data ext3 defaults 0 1 "| sudo tee --append  /etc/fstab

sudo apt-get -y -q install postgresql postgresql-contrib
sudo service postgresql stop

sudo rsync -av /var/lib/postgresql  /opt/postgresql_data
sudo rm -r /var/lib/postgresql/
sudo ln -s /opt/postgresql_data/postgresql /var/lib/postgresql

sudo service postgresql start
