#!/bin/bash

# Determine DAIR region
_region=""
_keystone=""
_ip=$(curl -s ifconfig.co)

case $_ip in
  199.116.232.*)
    _region="honolulu"
    _keystone="dair-hnl-v02.dair-atir.canarie.ca"
    ;;
  208.75.74.*)
    _region="alberta"
    _keystone="nova-ab.dair-atir.canarie.ca"
    ;;
  162.244.228.*)
    _region="alberta"
    _keystone="nova-ab.dair-atir.canarie.ca"
    ;;
  208.75.75.*)
    _region="quebec"
    _keystone="nova-ab.dair-atir.canarie.ca"
    ;;
esac

echo "export OS_TENANT_ID=%TENANTID%
export OS_USERNAME=%USERNAME%
export OS_PASSWORD='%PASSWORD%'
export OS_AUTH_URL=https://${_keystone}:5000/v2.0/
export OS_AUTH_STRATEGY=keystone
export OS_REGION_NAME=${_region}" >> /root/openrc

if (python -mplatform | grep -qi Ubuntu)
then #Ubuntu
    apt-get install -y python-pip python-swiftclient
else #CentOS
    yum install -y python-setuptools
    easy_install pip
    pip install --upgrade setuptools
    pip install python-swiftclient python-keystoneclient
    pip install --upgrade --force-reinstall 'requests==2.6.0'
    pip install --upgrade --force-reinstall 'six==1.9.0'
    pip install --upgrade --force-reinstall 'urllib3==1.10.2'
fi

mkdir /var/lib/postgres_backups
cat << 'EOF' | sudo tee -a  /usr/local/bin/backup_postgres.sh
#!/bin/bash
backup_dir="/var/lib/postgres_backups"
filename="postgres-`hostname`-`eval date +%Y%m%d`.sql.gz"
fullpath="${backup_dir}/${filename}"

# Dump the entire  database
pg_dumpall -U postgres -h localhost | gzip > $fullpath

if [[ $? != 0 ]]; then
  echo "Error dumping database"
  exit 1
fi

# Delete backups older than 20 days
find $backup_dir -ctime +20 -type f -delete

# Upload to swift
source /root/openrc
cd $backup_dir
swift upload postgresql_murano_backups  $filename > /dev/null
if [[ $? != 0 ]]; then
  echo "Error uploading backup"
  exit 1
fi
EOF
chmod +x  /usr/local/bin/backup_postgres.sh
crontab -l > mycron 2>/dev/null
echo "30 03 */10 * * /usr/local/bin/backup_postgres.sh > /dev/null" >> mycron
echo "30 03 01 */3 * /usr/local/bin/backup_postgres.sh > /dev/null" >> mycron
crontab mycron
rm -f  mycron
