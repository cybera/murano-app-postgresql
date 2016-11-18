#!/bin/bash

echo "export OS_TENANT_NAME=%TENANT%
export OS_USERNAME=%USERID%
export OS_PASSWORD=%PASSWORD%
export OS_AUTH_URL="https://dair-hnl-v02.dair-atir.canarie.ca:5000/v2.0/"
export OS_AUTH_STRATEGY=keystone
export OS_REGION_NAME=honolulu" >> /home/ubuntu/openrc

sudo apt-get install -y python-pip
sudo apt-get -y install python-swiftclient

sudo mkdir /var/lib/postgres_backups
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
    source /home/ubuntu/openrc
    cd $backup_dir
    swift upload postgresql $filename > /dev/null
    if [[ $? != 0 ]]; then
        echo "Error uploading backup"
          exit 1
        fi
EOF
sudo chmod +x  /usr/local/bin/backup_postgres.sh
sudo crontab -l > mycron 2>/dev/null
echo "30 03 */10 * * /usr/local/bin/backup_postgres.sh > /dev/null" >> mycron
echo "30 03 01 */3 * /usr/local/bin/backup_postgres.sh > /dev/null" >> mycron
sudo crontab mycron
rm mycron
