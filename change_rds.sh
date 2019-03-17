#!/bin/sh

#parameter
IOPS='1024 2048 4096 8192 16384'
#IOPS='1024 2048 4096 8192 16384 32768'

#MySQL
DBIdentifier='db01'

#Test
TESTCOMMAND='./Test.sh'

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
        echo "$(date '+%Y/%m/%d %H:%m:%S'):  IOPS=${iops} is same to current RDS. skip"    
    else 
        #change iops
        echo "$(date '+%Y/%m/%d %H:%m:%S'): change RDS IOPS"
        aws rds modify-db-instance \
            --db-instance-identifier ${DBIdentifier} \
            --allocated-storage ${RDS_SIZE} \
            --iops ${iops} \
            --apply-immediately;

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
                echo "$(date '+%Y/%m/%d %H:%m:%S'): DBInstanceStatus= ${STAT}"
                sleep 15
            fi
        done
        echo "$(date '+%Y/%m/%d %H:%m:%S'): modify done"
    fi
        
    #test
    echo "$(date '+%Y/%m/%d %H:%m:%S'): kick test program"
    ${TESTCOMMAND}
    echo "$(date '+%Y/%m/%d %H:%m:%S'): finished test program"
done

#end
echo "$(date '+%Y/%m/%d %H:%m:%S'): change_rds.sh: ALL COMPLETED!!!!"

