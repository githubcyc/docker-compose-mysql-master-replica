This repo demonstrates how to setup a mysql master replica using docker-compose and the official mysql docker image.


## Get Started

* Replica Pairs

```
cp .env.example .env

docker-compose up -d

docker logs -ft mysql_configure

// stop & remove
docker-compose down
```

### Query result

```
docker exec -ti mysql_master bash
mysql -u root -p -h 127.0.0.1 -P 3306
> show databases;

docker exec -ti mysql_replica bash
mysql -u root -p -h 127.0.0.1 -P 3306
> use test;
> select * from test;
```

* some issues

> authentication with sha2

```
docker logs -ft mysql_master
docker logs -ft mysql_replica

default_authentication_plugin=caching_sha2_password
```

> fork from here, For detailed article refere to [mysql](http://tarunlalwani.com/post/mysql-master-slave-using-docker)

## Refer

* [MySQL :: MySQL 8.0 Reference Manual :: 18.4.1.1 Single-Primary Mode](https://dev.mysql.com/doc/refman/8.0/en/group-replication-single-primary-mode.html)
* [bergerx/docker-mysql-replication](https://github.com/bergerx/docker-mysql-replication)
* [gritt/docker-mysql-replication: master master & master replica replication in mysql](https://github.com/gritt/docker-mysql-replication)
