#!/bin/sh

#parameter
IOPS='2048 8192 16384'
#IOPS='1024 2048 4096 8192 16384 32768'

#MySQL
DBIdentifier='db01'

#Test
TEST_COMMAND='./Test.sh'
TEST_TIMES=3

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


for iops in ${IOPS}
do
    # Change IOPS
    if [ "A${iops}" == "A${RDS_IOPS}" ]; then
        echo "$(date '+%Y/%m/%d %H:%M:%S'):  IOPS=${iops} is same to current RDS. skip"    
    else 
        #change iops
        echo "$(date '+%Y/%m/%d %H:%M:%S'): change RDS IOPS"
        aws rds modify-db-instance \
            --db-instance-identifier ${DBIdentifier} \
            --allocated-storage ${RDS_SIZE} \
            --iops ${iops} \
            --apply-immediately;

    fi
    # Wait
    sleep 30
    while true
    do
        STAT=$(aws --output text rds describe-db-instances \
            --db-instance-identifier ${DBIdentifier} \
            --query 'DBInstances[].DBInstanceStatus')
        if [ "A${STAT}" == "Aavailable" ]; then
            break
        else
            echo "$(date '+%Y/%m/%d %H:%M:%S'): DBInstanceStatus= ${STAT}"
            sleep 15
        fi
    done
    echo "$(date '+%Y/%m/%d %H:%M:%S'): modify done"
        
    #test
    for runs in $(seq 1 ${TEST_TIMES})
    do
        echo "$(date '+%Y/%m/%d %H:%M:%S'): kick test program(${runs}th time)"
        ${TEST_COMMAND}
        echo "$(date '+%Y/%m/%d %H:%M:%S'): finished test program"
    done
done

#end
echo "$(date '+%Y/%m/%d %H:%M:%S'): change_rds.sh: ALL COMPLETED!!!!"

