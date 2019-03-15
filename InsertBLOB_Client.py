#!/bin/env python

import mysql.connector
from mysql.connector import Error
from mysql.connector import errorcode
import sys
import datetime
import threading
from Queue import Queue

host='db01.c15bz8qunqqh.ap-northeast-1.rds.amazonaws.com'
database='testdb'
user='awsuser'
password='awsuser1'


def print_status(executecount, parallelCount,ExecuteNo):
    date = datetime.datetime.now()
    rows = executecount // parallelCount
    print("{} : Commit {} rows (ExecuteNo {})".format(date, rows, ExecuteNo))

def convertToBinaryData(filename):
    # Convert digital data to binary format
    with open(filename, 'rb') as file:
        binaryData = file.read()
        return binaryData

def insertBLOB(executeNo, parallelCount, insertCount, fileName, ThreadNo, ret):
    try:
        # DB Connect
        connection = mysql.connector.connect( host=host, database=database, user=user, password=password, use_pure=True)
        cursor = connection.cursor(prepared=True)

        # Loading file data
        filedata = convertToBinaryData(fileName)

        # record starting time
        first_time = datetime.datetime.now()

        count = 0
        for executecount in range(executeNo, insertCount, parallelCount):
            # Create insert statement
            sql_insert_blob_query = """ INSERT INTO `testtbl01`(`file_id`, `file_body`) VALUES (%s,%s)"""

            # Convert data into tuple format
            insert_blob_tuple = (executecount, filedata)

            # Insert Operation
            result  = cursor.execute(sql_insert_blob_query, insert_blob_tuple)
            count += 1

            # Commit
            if ( count % 1000 ) == 0:
                connection.commit()
                print_status(executecount, parallelCount, executeNo)

        connection.commit()

        #last 
        last_time = datetime.datetime.now()
        
        #print result 
        delta = last_time - first_time
        print("ThreadNo: {}, ExecutionTime(sec): {}, NumberOfInsertFiles: {},Start: {}, Finish: {}".format( ThreadNo, delta.total_seconds(), count, first_time, last_time ) )

    except mysql.connector.Error as error :
        connection.rollback()
        print("Failed!!")

    finally:
        # closing database connection.
        if(connection.is_connected()):
            # Close cursor
            cursor.close()
            #print("Cursor is closed.")
            connection.close()
            #print("Connection is closed.")

    ret.put(count)



def Launch_insertBLOB(executeNo, parallelCount, insertCount, fileName):

    threads = []
    ret = Queue()
    # creat threads
    for i in range(0, parallelCount):
        t = threading.Thread(target=insertBLOB, args=(executeNo+i,  parallelCount, insertCount, fileName, i, ret))
        threads.append(t)

    # record starting time
    first_time = datetime.datetime.now()

    # start threads
    for t in threads:
        t.start()

    # wait threads
    for t in threads:
        t.join()
     
    #last 
    last_time = datetime.datetime.now()
       
    #calclate the result
    delta = last_time - first_time
    count=0
    while True:
        if ret.empty():
            break
        else:
            count += ret.get()

    #print the result
    print("ALL_ExecutionTime(sec):{}".format( delta.total_seconds() ))
    print("ALL_NumberOfInsertFiles:{}".format( count ))
    print("ALL_Start:{}".format( first_time ))
    print("ALL_Finish:{}".format( last_time ))
        
if __name__ == "__main__":

    args = sys.argv
    executeNo     = int(args[1])
    parallelCount = int(args[2])
    insertCount   = int(args[3])
    fileName      = args[4]

    Launch_insertBLOB(executeNo, parallelCount, insertCount, fileName)

