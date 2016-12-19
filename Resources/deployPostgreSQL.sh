#!/bin/bash

vol='/dev/'$(sudo lsblk -o name,type,mountpoint,label,uuid | grep -v root | grep -v ephem | grep -v SWAP | grep -v vda | tail -1 |awk '{print $1}')

sudo mkfs -t ext4 $vol
sudo mkdir /opt/postgresql_data
sudo mount $vol /opt/postgresql_data
echo "$vol /opt/postgresql_data ext4 defaults 0 1 " | sudo tee --append  /etc/fstab

sudo apt-get -y -q install postgresql postgresql-contrib
location1=$(echo $(sudo -u postgres psql -c "show config_file";) | awk '{print $3}')
location2=$(echo $(sudo -u postgres psql -c "show hba_file";) | awk '{print $3}')
sudo service postgresql stop

sudo rsync -av /var/lib/postgresql  /opt/postgresql_data
sudo rm -rf /var/lib/postgresql/
sudo ln -s /opt/postgresql_data/postgresql /var/lib/postgresql

tmp="%CONNECTION_IP%"
if  [[ !  -z  $tmp  ]]
then
  echo "host    all             all             %CONNECTION_IP%/32            md5" | sudo tee --append $location2
  sudo sed -i -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" $location1
fi

sudo service postgresql start
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '%POSTGRES_PASSWORD%';"
echo "*:*:*:postgres:%POSTGRES_PASSWORD%" | sudo tee --append /root/.pgpass
sudo chmod 600 /root/.pgpass
