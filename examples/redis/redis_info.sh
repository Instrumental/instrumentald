#! /bin/bash

REDIS_HOST=${REDIS_HOST:-"127.0.0.1"}
REDIS_PORT=${REDIS_PORT:-"6379"}

all_redis_info=`redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" info`
main_info=`echo "$all_redis_info" | grep -e "connected_clients" -e "instantaneous_ops_per_sec" | sed 's/:/ /g'`
db_key_info=`echo "$all_redis_info" | grep "keys=" | sed 's/:/_/g' | sed 's/=/ /g' | sed 's/,.*//g'`

printf "%s\r\n%s\r\n" "$main_info" "$db_key_info"
