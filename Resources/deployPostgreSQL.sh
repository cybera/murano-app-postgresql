#!/bin/bash

vol='/dev/'$(lsblk -o name,type,mountpoint,label,uuid | grep -v root | grep -v ephem | grep -v SWAP | grep -v vda | tail -1 |awk '{print $1}')

mkfs -t ext4 $vol
mkdir /opt/postgresql_data
mount $vol /opt/postgresql_data
echo "$vol /opt/postgresql_data ext4 defaults 0 1 " | tee --append  /etc/fstab

if (python -mplatform | grep -qi Ubuntu)
then #Ubuntu
  apt-get -y update
  apt-get -y -q install postgresql postgresql-contrib
  service postgresql stop
  rsync -av /var/lib/postgresql  /opt/postgresql_data
  rm -rf /var/lib/postgresql/
  ln -s /opt/postgresql_data/postgresql /var/lib/postgresql

else #CentOS
  yum clean all
  yum install -y centos-release-openstack-mitaka
  yum -y  update
  yum install postgresql-server postgresql-contrib
  systemctl enable postgresql
  #chown -R postgres:postgres /opt/postgresql_data
  #chmod 700 /opt/postgresql_data
  mv /var/lib/pgsql/data /opt/postgresql_data/data
  ln -s /opt/postgresql_data/data /var/lib/pgsql/data
  postgresql-setup initdb
  setenforce 0
  sed -i -e "s|enforcing|disabled|g" /etc/selinux/config
fi

location1=$(echo $(sudo -u postgres psql -c "show config_file";) | awk '{print $3}')
location2=$(echo $(sudo -u postgres psql -c "show hba_file";) | awk '{print $3}')
sed -i -e "s/ident/trust/g" $location2

tmp="%CONNECTION_IP%"
if  [[ !  -z  $tmp  ]]
then
  echo "host    all             all             %CONNECTION_IP%/32            md5" | tee --append $location2
  sed -i -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" $location1
  sed -i -e "s/ident/trust/g" $location2
fi

if (python -mplatform | grep -qi Ubuntu)
then #Ubuntu
  service postgresql restart
else #CentOS
  systemctl restart postgresql
fi

sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '%POSTGRES_PASSWORD%';"
echo "*:*:*:postgres:%POSTGRES_PASSWORD%" | tee --append /root/.pgpass
chmod 600 /root/.pgpass
