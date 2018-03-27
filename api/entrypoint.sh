#!/bin/bash

set -e
host=$DB_HOST; 
port=5432; 
n=120; 
i=0; 
while ! (echo > /dev/tcp/$host/$port) 2> /dev/null; do 
    [[ $i -eq $n ]] && >&2 echo "$host:$port not up after $n seconds, exiting" && exit 1;
    echo "waiting for $host:$port to come up";
    sleep 1;
    i=$((i+1));
done

cmd="$@"

until PGPASSWORD=postgres psql -h "db" -U "postgres" -c '\q'; do
  >&2 echo "waiting for postgres"
  sleep 1
done

>&2 echo "connected to postgres"

while ! nc -z redis 6379;
do
  echo sleeping;
  sleep 1;
done;
echo "connected to redis";

exec uwsgi --ini uwsgi.ini

