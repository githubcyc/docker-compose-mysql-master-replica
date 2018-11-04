#!/bin/bash
BASE_PATH=$(dirname $0)

echo "Waiting for mysql to get up"
# Give 60 seconds for master and replica to come up
sleep 60

echo "Create MySQL Servers (master / repl)"
echo "-----------------"

echo "env"
echo "$MYSQL_REPLICA_PASSWORD"
echo "$MYSQL_MASTER_PASSWORD"
echo "$MYSQL_ROOT_PASSWORD"
echo "$MYSQL_REPLICATION_USER"
echo "$MYSQL_REPLICATION_PASSWORD"

echo "* Create replication user"

mysql --host mysql_replica -uroot -p$MYSQL_REPLICA_PASSWORD -AN -e 'STOP SLAVE;';
mysql --host mysql_master -uroot -p$MYSQL_MASTER_PASSWORD -AN -e 'RESET SLAVE ALL;';

# 'repl'@'192.168.0.%'
# https://dev.mysql.com/doc/refman/8.0/en/replication-howto-repuser.html
# mysql> CREATE USER 'repl'@'%.example.com' IDENTIFIED BY 'password';
# mysql> GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%.example.com';
# mysql> show grants for repl;
mysql --host mysql_master -uroot -p$MYSQL_MASTER_PASSWORD -AN -e "CREATE USER '$MYSQL_REPLICATION_USER'@'%' IDENTIFIED WITH mysql_native_password BY '$MYSQL_REPLICATION_PASSWORD';"
mysql --host mysql_master -uroot -p$MYSQL_MASTER_PASSWORD -AN -e "GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO '$MYSQL_REPLICATION_USER'@'%';"
mysql --host mysql_master -uroot -p$MYSQL_MASTER_PASSWORD -AN -e 'flush privileges;'


echo "* Set MySQL01 as master on MySQL02"

MYSQL01_Position=$(eval "mysql --host mysql_master -uroot -p$MYSQL_MASTER_PASSWORD -e 'show master status \G' | grep Position | sed -n -e 's/^.*: //p'")
MYSQL01_File=$(eval "mysql --host mysql_master -uroot -p$MYSQL_MASTER_PASSWORD -e 'show master status \G'     | grep File     | sed -n -e 's/^.*: //p'")
MASTER_IP=$(eval "getent hosts mysql_master|awk '{print \$1}'")
echo $MASTER_IP
mysql --host mysql_replica -uroot -p$MYSQL_REPLICA_PASSWORD -AN -e "CHANGE MASTER TO master_host='mysql_master', master_port=3306, \
        master_user='$MYSQL_REPLICATION_USER', master_password='$MYSQL_REPLICATION_PASSWORD', master_log_file='$MYSQL01_File', \
        master_log_pos=$MYSQL01_Position;"

echo "* Set MySQL02 as master on MySQL01"

MYSQL02_Position=$(eval "mysql --host mysql_replica -uroot -p$MYSQL_REPLICA_PASSWORD -e 'show master status \G' | grep Position | sed -n -e 's/^.*: //p'")
MYSQL02_File=$(eval "mysql --host mysql_replica -uroot -p$MYSQL_REPLICA_PASSWORD -e 'show master status \G'     | grep File     | sed -n -e 's/^.*: //p'")

REPLICA_IP=$(eval "getent hosts mysql_replica|awk '{print \$1}'")
echo $REPLICA_IP
mysql --host mysql_master -uroot -p$MYSQL_MASTER_PASSWORD -AN -e "CHANGE MASTER TO master_host='mysql_replica', master_port=3306, \
        master_user='$MYSQL_REPLICATION_USER', master_password='$MYSQL_REPLICATION_PASSWORD', master_log_file='$MYSQL02_File', \
        master_log_pos=$MYSQL02_Position;"

echo "* Start Replica on both Servers"
mysql --host mysql_replica -uroot -p$MYSQL_REPLICA_PASSWORD -AN -e "start slave;"

echo "Increase the max_connections to 2000"
mysql --host mysql_master -uroot -p$MYSQL_MASTER_PASSWORD -AN -e 'set GLOBAL max_connections=2000';
mysql --host mysql_replica -uroot -p$MYSQL_REPLICA_PASSWORD -AN -e 'set GLOBAL max_connections=2000';

mysql --host mysql_replica -uroot -p$MYSQL_REPLICA_PASSWORD -e "show slave status \G"
mysql --host mysql_master -uroot -p$MYSQL_MASTER_PASSWORD -AN -e 'source /tmp/test.sql;'

echo "MySQL servers created!"
echo "--------------------"
echo
echo Variables available fo you :-
echo
echo MYSQL01_IP       : mysql_master
echo MYSQL02_IP       : mysql_replica

