#!/bin/bash
# Thomas Kapoulas <thomas.kapoulas@gmail.com>
# Backup script for www-data files, mysql dbs with mail notification via sendmail

## config variables
# backup directory
BACKUPDIR="/root/backups"
# mysql root password
MYSQLPASS="changeme"
# keep backups only newer than <define> days
HOWOLD="60"
# mail of the site owner
EMAIL="changeme@changeme.tld"

###################################################################
## util variables
D=`date +'%d-%m-%Y'`
WWWDIR="/var/www"
MD5IT="/usr/bin/md5sum"
SM="/usr/sbin/sendmail"
MYSQLDUMP="/usr/bin/mysqldump"
MYSQL="/usr/bin/mysql"

## gzip www-data files & mysql db
chown -R www-data:www-data $WWWDIR
mkdir /tmp/backup-$D
ls -l $WWWDIR > /tmp/backup-$D/www-data.includes
tar -cf /tmp/backup-$D/www-data.tar $WWWDIR

# get a list of databases
DATABASES=`$MYSQL --user=root --password=$MYSQLPASS -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`

# dump each database in turn
for DB in $DATABASES; do
    echo $DB
    $MYSQLDUMP --force --opt --user=root --password=$MYSQLPASS --databases $DB > /tmp/backup-$D/$DB.sql
done
tar -czf $BACKUPDIR/backup-$D.tar.gz /tmp/backup-$D
rm -rf /tmp/backup-$D

## create md5 checksum files
$MD5IT $BACKUPDIR/backup-$D.tar.gz > $BACKUPDIR/backup-$D.md5sum

## delete backup files older than $HOWOLD days
find $BACKUPDIR/* -mtime +$HOWOLD -exec rm {} \;

## mail the site owner
echo "From: backup@"$HOSTNAME > /tmp/backup.mail
echo "To: "$EMAIL >> /tmp/backup.mail
echo "Subject: ["$D"] Your backup is ready." >> /tmp/backup.mail
echo "Your backup files are located in "$BACKUPDIR >> /tmp/backup.mail
$SM -t root < /tmp/backup.mail
rm /tmp/backup.mail

