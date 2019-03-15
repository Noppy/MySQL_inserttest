#!/bin/sh

#parameter
IOPS='32768 1024 2048 4096 8192 16384'

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
        echo "IOPS=${iops} is same to current RDS. skip"    
    else 
        #change iops
        echo "change RDS IOPS"
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
                echo ${STAT} 
                sleep 15
            fi
        done
        echo "modify done"
    fi
        
    #test
    ${TESTCOMMAND}    

done

#end
echo "ALL COMPLETED!!!!"

