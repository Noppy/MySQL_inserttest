#!/bin/sh

#dynamodb
DynamodbTable='MySQLBench'
csvfile="${DynamodbTable}.csv"

# export from dynamodb
echo '"RdsInstanceType","RdsIops","RdsSize","ClientInstanceType","UploadFileSize","UploadFileName","Parallel","ResultTime","ResultObjects","ResultThroughputSizePerSec","ResultThroughputFilePerSec","ResultStart","ResultFinish"' > ${csvfile}

aws --output json dynamodb scan --table-name ${DynamodbTable} | jq -r -c '
        .Items[] | [
            .RdsInstanceType.S,
            .RdsIops.N,
            .RdsSize.N,
            .RdsStorageType.S,
            .ClientInstanceType.S,
            .UploadFileSize.N,
            .UploadFileName.S,
            .Parallel.N,
            .ResultTime.N,
            .ResultObjects.N,
            .ResultThroughputSizePerSec.N,
            .ResultThroughputFilePerSec.N,
            .ResultStart.Si,
            .ResultFinish.S
        ] | @csv'  >> ${csvfile}
