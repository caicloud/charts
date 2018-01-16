#!/bin/bash

# ENVS:
# GALERA_CLUSTER_DOMAIN=galera
# GALERA_CHECK_DELAY=5
# GALERA_CLUSTER_NAME=mysql_cluster
# GALERA_USER=sst
# GALERA_PASSWORD=sstpassword
# MYSQL_ROOT_PASSWORD=root
# MYSQL_DATABASE=db
# MYSQL_USER=user
# MYSQL_PASSWORD=password

# check envs
oldIFS=$IFS
IFS=','
GALERA_ENVS=GALERA_CLUSTER_DOMAIN,GALERA_START_DELAY,GALERA_CLUSTER_NAME,GALERA_USER,GALERA_PASSWORD,MYSQL_ROOT_PASSWORD
for env in ${GALERA_ENVS[@]}; do
  if [[ -z "${!env}" ]]; then
    echo >&2 "error: ${env} is not set"
    exit 1
  fi
done
IFS=$oldIFS

# get current node index in galera cluster
INDEX=${HOSTNAME##*-}
expr $INDEX '+' 1000 &>/dev/null
if [ "$?" -ne 0 ]; then
  echo >&2 'error: start without StatefulSet and HOSTNAME is wrong'
  exit 1
fi

echo "HOSTNAME: ${HOSTNAME}"
echo "GALERA_CLUSTER_DOMAIN: ${GALERA_CLUSTER_DOMAIN}"
echo "GALERA_START_DELAY: ${GALERA_START_DELAY}"
echo "GALERA_CLUSTER_NAME: ${GALERA_CLUSTER_NAME}"
echo "GALERA_USER: ${GALERA_USER}"
echo "INDEX: ${INDEX}"

# initiate db when it is not existing
firstTime=0
if [ ! -d '/var/lib/mysql/mysql' ]; then
  # install db
  echo "Info: Initialize DB"
  set -e
  mysqld --initialize --user=mysql --datadir=/var/lib/mysql
  chown -R mysql:mysql /var/lib/mysql
  set +e
  echo "Info: Installed DB"
  firstTime=1
fi

echo "Info: Check alive"

# check if the cluster is running
alive=0
check() {
  oldIFS=$IFS
  IFS=','
  nodes=($GALERA_CLUSTER_ADDRESS)
  IFS=$oldIFS
  pids=""
  for node in ${nodes[@]}; do
    timeout 2 bash -c "mysql -h$node -uroot -p$MYSQL_ROOT_PASSWORD -e 'select 1' 2>/dev/null 1>/dev/null" &
    pids="$pids $!"
  done
  for pid in $pids; do
    wait $pid
    if [ "$?" -eq 0 ]; then
      alive=1
      break
    fi
  done
}

# if the cluster is not alive,try check cluster status every GALERA_START_DELAY seconds
times=$INDEX
while [ $times -ge 0 ]; do
  # get available node IPs.
  GALERA_CLUSTER_ADDRESS=$(resolveip "$GALERA_CLUSTER_DOMAIN" | awk '{print $6}')
  GALERA_CLUSTER_ADDRESS=$(printf ",%s" $GALERA_CLUSTER_ADDRESS)
  GALERA_CLUSTER_ADDRESS=${GALERA_CLUSTER_ADDRESS#,*}
  echo "Check alive countdown: ${times}"
  echo "GALERA_CLUSTER_ADDRESS: ${GALERA_CLUSTER_ADDRESS}"

  if [[ $GALERA_CLUSTER_ADDRESS != "" ]]; then
    check
    if [ "$alive" -ne 0 -o "$times" -eq 0 ]; then
      break
    fi
  fi

  sleep $GALERA_START_DELAY
  times=$(($times - 1))
done

# configure galera:/etc/mysql/galera.cnf
configFile='/etc/mysql/galera.cnf'
sed -i "s|^wsrep_cluster_name.*$|wsrep_cluster_name=\"$GALERA_CLUSTER_NAME\"|g" "$configFile"
sed -i "s|^wsrep_cluster_address.*$|wsrep_cluster_address=\"gcomm://$GALERA_CLUSTER_ADDRESS\"|g" $configFile
sed -i "s|^wsrep_sst_auth.*$|wsrep_sst_auth=$GALERA_USER:$GALERA_PASSWORD|g" $configFile

if [ "$alive" -eq 0 ]; then
  # set --wsrep-new-cluster
  echo "Info: $GALERA_CLUSTER_NAME is not running, start a new cluster"
  set -- "$@" --wsrep-new-cluster
else
  echo "Info: $GALERA_CLUSTER_NAME is running, join cluster"
fi

# generate a init.sql
if [ "$firstTime" -eq 1 -a "$alive" -eq 0 ]; then
  tempFile='/tmp/first.sql'
  cat >"$tempFile" <<-EOF
DELETE FROM mysql.user ;
CREATE USER 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD' ;
GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
CREATE USER '$GALERA_USER'@'%' IDENTIFIED BY '$GALERA_PASSWORD' ;
GRANT ALL ON *.* TO '$GALERA_USER'@'%' WITH GRANT OPTION ;
DROP DATABASE IF EXISTS test ;
EOF

  if [ "$MYSQL_DATABASE" ]; then
    echo "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE ;" >>"$tempFile"
  fi

  if [ "$MYSQL_USER" -a "$MYSQL_PASSWORD" ]; then
    echo "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' ;" >>"$tempFile"

    if [ "$MYSQL_DATABASE" ]; then
      echo "GRANT ALL ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%' ;" >>"$tempFile"
    fi
  fi

  echo 'FLUSH PRIVILEGES ;' >>"$tempFile"

  # use initial script when current node is the most advanced node of galera
  if [ -f './init.sql' ]; then
    cat ./init.sql >>"$tempFile"
  fi

  set -- "$@" --init-file="$tempFile"
fi
echo "Info: $@"
exec "$@"
