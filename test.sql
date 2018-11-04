CREATE DATABASE test;
use test;
create table test(id int not null, name varchar(100));
insert into test values(1, 'from master');
select * from test;