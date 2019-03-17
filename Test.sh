#!/bin/sh

#parameter
Parallel='1 2 4 8 16 32 64 128 256'
NumObjects=30000
insertfile='test_1KB.dat test_2KB.dat  test_4KB.dat  test_8KB.dat test_16KB.dat test_32KB.dat  test_64KB.dat  test_128KB.dat test_256KB.dat'

#dynamodb
DynamodbTable='MySQLBench'

#MySQL
DBIdentifier='db01'
db_endpoint='db01.c15bz8qunqqh.ap-northeast-1.rds.amazonaws.com'
dbname='testdb'
port=3306
user='awsuser'
passwd='awsuser1'
table_name='testtbl01'

#TestProgram
interval=30
TestProgram='./InsertBLOB_Client.py'

#get client instance
ClientInstanceType=$(curl -sS http://169.254.169.254/latest/meta-data/instance-type)

#Main--------------------
echo "$(date '+%Y/%m/%d %H:%M:%S'): start test program."

#Get RDS status
RDS_InstanceType=$(aws --output text rds describe-db-instances \
        --db-instance-identifier ${DBIdentifier} \
        --query 'DBInstances[].DBInstanceClass[]');
RDS_IOPS=$(aws --output text rds describe-db-instances \
        --db-instance-identifier ${DBIdentifier} \
        --query 'DBInstances[].Iops[]');
RDS_SIZE=$(aws --output text rds describe-db-instances \
        --db-instance-identifier ${DBIdentifier} \
        --query 'DBInstances[].AllocatedStorage[]');
RDS_STORAGE=$(aws --output text rds describe-db-instances \
        --db-instance-identifier ${DBIdentifier} \
        --query 'DBInstances[].StorageType[]');



# bench mark
for filename in ${insertfile}
do
    for i in ${Parallel}
    do
        #Create Key
        PrimaryKey=$(date '+%Y%m%d%H%M%S%N')
    
        #Get Parameter
        FileSize=$(ls -l ${filename}|cut -f 5 -d ' ')

        #print header
        echo '-----------------------'
        echo "Client InstanceType= ${ClientInstanceType}"
        echo "RDS InstanceType   = ${RDS_InstanceType}"
        echo "RDS StorageType    = ${RDS_STORAGE}"
        echo "RDS IOPS           = ${RDS_IOPS}"
        echo "RDS SIZE           = ${RDS_SIZE}"
        echo "Upload_Filename    = ${filename}"
        echo "Upload_filesize    = ${FileSize}"
        echo "Number of Uplodad  = ${NumObjects}"
        echo "parallel           = ${i}"

        #clear table
        echo "$(date '+%Y/%m/%d %H:%M:%S') truncate a table"
        mysql -h ${db_endpoint} -D ${dbname} -P ${port} -u ${user} -p${passwd} \
            -e "truncate ${table_name}; select count(file_id) from ${table_name};";
        sleep ${interval}
        
        # test
        echo "$(date '+%Y/%m/%d %H:%M:%S') kick MySQL insert test program"
        ${TestProgram} 0 ${i} ${NumObjects} ${filename} | tee /tmp/test.log
        echo "$(date '+%Y/%m/%d %H:%M:%S') finished MySQL insert test program"

        # get the result
        ResultTime=$(grep 'ALL_ExecutionTime(sec):' /tmp/test.log | sed -e 's/ALL_ExecutionTime(sec)://')
        ResutlObje=$(grep 'ALL_NumberOfInsertFiles:' /tmp/test.log | sed -e 's/ALL_NumberOfInsertFiles://')
        ResultStart=$(grep 'ALL_Start:' /tmp/test.log | sed -e 's/ALL_Start://')
        ResultFinish=$(grep 'ALL_Finish:' /tmp/test.log | sed -e 's/ALL_Finish://')
        ThroughputSizePerSec=$(echo 'scale=2; '"${FileSize}"' * '"${ResutlObje}"' / '"${ResultTime}" | bc)
        ThroughputfilePerSec=$(echo 'scale=2; '"${ResutlObje}"' / '"${ResultTime}" | bc)

        # insert result
        aws dynamodb put-item --table-name ${DynamodbTable} \
            --item '{ 
                "Time": {"S": "'${PrimaryKey}'"},
                "RdsInstanceType": {"S": "'${RDS_InstanceType}'"},
                "RdsIops": {"N": "'${RDS_IOPS}'"},
                "RdsSize": {"N": "'${RDS_SIZE}'"},
                "RdsStorageType": {"S": "'"${RDS_STORAGE}"'"},
                "ClientInstanceType": {"S": "'${ClientInstanceType}'"},
                "UploadFileSize": {"N": "'${FileSize}'"},
                "UploadFileName": {"S": "'${filename}'"},
                "Parallel": {"N": "'${i}'"},
                "ResultTime": {"N": "'${ResultTime}'"},
                "ResultObjects": {"N": "'${ResutlObje}'"},
                "ResultStart": {"S": "'"${ResultStart}"'"},
                "ResultFinish": {"S": "'"${ResultFinish}"'"},
                "ResultThroughputSizePerSec": {"N": "'"${ThroughputSizePerSec}"'"},
                "ResultThroughputFilePerSec": {"N": "'"${ThroughputfilePerSec}"'"}
            }' 
    done
done

#end
echo "$(date '+%Y/%m/%d %H:%M:%S'): ALL COMPLETED!!!!"
