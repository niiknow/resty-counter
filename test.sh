#!/bin/bash
LOGDIR="data/logs/*.plog";
COUNTER=0;

  # sync all access log files modified more than 2 hours ago
  # this mean current date file should not be included if
  # you have something correctly hitting health check
  for line in `ls -t $LOGDIR`
  do
    #echo $line;
    file=`echo $line | awk -F "/" '{ print $NF }'`;
    #echo $file;
    YEAR=`echo $file | cut -d "-" -f 1`;
    MONTH=`echo $file | cut -d "-" -f 2`;
    DAY=`echo $file | cut -d "-" -f 3`;
    HOUR=`echo $file | cut -d "-" -f 4`;

    # only process with valid month
    if [ ! -z "$MONTH"  ]; then
      # skip first file found
      COUNTER=$(expr $COUNTER + 1)
      if [ $COUNTER -gt 1 ]; then
        echo $line 'hi'
      fi
    fi
  done