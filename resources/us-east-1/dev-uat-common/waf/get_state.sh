#!/bin/bash

while getopts 'k:b:' options
do
  case $options in
    b) 
      bucket=$OPTARG 
      ;;
    k) 
      key=$OPTARG 
      ;;
  esac
done
shift $((OPTIND -1))

key=${key:?'Key is required'}
bucket=${bucket:?'Bucket is required'}

aws s3 cp s3://${bucket}/${key} ${key} > /dev/null 2>&1
cat ${key} | jq '.outputs| with_entries(.value = (.value.value))'