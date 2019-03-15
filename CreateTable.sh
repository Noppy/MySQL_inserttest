#!/bin/sh

#MySQL
DBIdentifier='db01'
db_endpoint='db01.c15bz8qunqqh.ap-northeast-1.rds.amazonaws.com'
dbname='testdb'
port=3306
user='awsuser'
passwd='awsuser1'
table_name='testtbl01'

#clear table
mysql -h ${db_endpoint} -D ${dbname} -P ${port} -u ${user} -p${passwd} \
    -e "create table ${table_name} (file_id int, file_body blob);
        alter table ${table_name} add constraint pk_${table_name} primary key (file_id);"
    
echo "ALL COMPLETED!!!!"

