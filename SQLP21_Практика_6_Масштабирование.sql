/*  �������� 6 ���������������
--��������� ���������� �� Windows
--1. "C:\Program Files\PostgreSQL\12\data\pg_hba.conf" - ���������
--������ ���� ����������������� 2 ������ ������
-- ������ ��������� postgresql.conf
wal_level = replica ( ���� logical)
max_wal_senders = 10
max_replication_slots = 10
hot standby = on ( ���� off - ��� �������� ���������� ����� � ������ ��������� �������, � �������� ������������ ������)
hot_standby_feedback = on ( ����� ����� �������� ��� �������, ������ ������������ ������� ��������� �� �������)
--������ ���� ���������������� #( ��� logical - �����������������)
--max_logical_replication_workers = 4	# taken from max_worker_processes
--(change requires restart)-max_sync_workers_per_subscription = 2	# taken from max_logical_replication_workers
��������� ����, ������������� ������ ����� ������ windows
����� ��������� ��������� ������, ��������� � bin � ��������� �������
pg_basebackup -R -X stream -c fast -h localhost -p 5432 -U postgres -D "c:\DataRepl" -- � ����� "c:\DataRepl" ��������� ����� ��� ��, ������ ���� ����������  � ���� ��� DZ, ����� public
����� � ����� c:/DataRepl ��������� Postgrsql.conf  � ������ ���� �� 5435
��������� ����, ��������� ������ ������� pg_ctl -D "C:\DataRepl" start
������� ����� ����������� postgres_replic, ��� ������ ��� � ���������, ����� �����*/
select * from pg_catalog.pg_stat_replication;
-- �������� ������ ������ ��������� �������.
--���� ��������� � ��������� ������� ��� ������� - ����� ����� (  �������� ������ ���� ���)
--� ������� ��� ������� ��������� DDL ������� ����� ���������, ��� ���������� �������� ������ �� ������. ��� ���������� ���������� �� ������� ��� ���������������� �� �������
-- �� �������
create schema aaaa;
set search_path to aaaa;
create table a(id int);
insert into a values(1);
--��� ���������� ���������� �� ������� ��� ���������������� �� �������
-- ����� �� ������� ���������� ����������
select pg_current_wal_lsn();--�� �������

--���� ��������� select pg_last_wal_receive_lsn() �� �������, �� ���  �� �� �����, 
select pg_last_wal_receive_lsn();-- �� �������
-- ����� ���������� ������� � ��������
select pg_wal_lsn_diff(pg_current_wal_lsn(),pg_last_wal_receive_lsn());
--��� ��������� ������ ������� �� ������������: 
pg_ctl promote -D "C:\DataRepl\" --����������� ������� ������� ������ ��������� �������

-- ���������� ����������
--1. "C:\Program Files\PostgreSQL\12\data\pg_hba.conf" - ���������
--������ ���� ����������������� 2 ������ ������
-- ������ ��������� postgresql.conf
--wal_level = logical ( ���� replica)
--max_wal_senders = 10
--max_replication_slots = 10
--hot standby = on ( ���� off - ��� �������� ���������� ����� � ������ ��������� �������, � �������� ������������ ������)
--hot_standby_feedback = on ( ����� ����� �������� ��� �������, ������ ������������ ������� ��������� �� �������)
--������ ���� ����������������� ( ��� replica - ����������������)
--max_logical_replication_workers = 4	# taken from max_worker_processes
--(change requires restart)-max_sync_workers_per_subscription = 2	# taken from max_logical_replication_workers
--��������� ����
-- ���� � postgresql.conf � ������, ������ ��� �� �� �����
--wal_level = logical ( ���� replica)
--max_wal_senders = 10
--max_replication_slots = 10
--hot standby = on ( ���� off - ��� �������� ���������� ����� � ������ ��������� �������, � �������� ������������ ������)
--hot_standby_feedback = on ( ����� ����� �������� ��� �������, ������ ������������ ������� ��������� �� �������)
--������ ���� ����������������� ( ��� replica - ����������������)
--max_logical_replication_workers = 4	# taken from max_worker_processes
--(change requires restart)-max_sync_workers_per_subscription = 2	# taken from max_logical_replication_workers
--��������� ����
--������������� ������ ����� ������ windows
--������� � ������� 2 ������� a � b, ������ ������. 
create table a(id int);
do $$
begin
	for i in 1..1000
	loop 
		insert into a (id)
		values (i);		
	end loop;	
end;
$$ language plpgsql

select * from a
select * from b
create table b(id int);
insert into b 
values (900);
--��������� � ������� , ��� ������ ���� ������� ������������ ����� �� ����� � ����� �� ��������� ������
--� ������� ������� ������ a, � � b ������ �� �� �������� ��� �� �������, � �������� ��� ������
/*set search_path to aaaa;
 * create table a(id int);
create table b(id int);
insert into b 
values (700);
insert into b 
values (200);*/ -- ���� �������� ������ �� �������

-- ����� ������� ���������� � �������� ������� � �������

create publication pub_t for table a, b;

create publication pub_t for all tables with (publish = 'insert')
-- ������ �� ������� ����� ������� �������� �� ������� ������� subscription - 
create subscription sub_t 
	connection 'host = localhost port = 5432 user = postgres password = 2305623056 dbname = postgres' 
	publication pub_t with (copy_data=true); -- � ���� ���������� ��� ������� �� ������� �������� ����� �����������. ������ ��� ����� ������ ������
alter subscription sub_t set publication pub_t with (copy_data=false);-- ������ �������� �� ������� , ����� ������ � ������
--������ �� a �  b ������ �� �������
alter table a add constraint a_u unique (id)
drop publication pub_t;
alter table a add column val int
alter table a add constraint a_pkey primary key (id)

delete from a
do $$
begin
	for i in 1..1000
	loop 
		insert into a (id, val)
		values (i, i);		
	end loop;	
end;
$$ language plpgsql
select * from a;
update a set val = 11111111 where id = 3

--�����������������
set search_path to public;
--��� ������������ �������, ������ ������ ����������������� �� �������
select distinct DATE_TRUNC('month', payment_date)
from payment p;
--������� ��������
create table payment_05_2005
(check (DATE_TRUNC('month', payment_date) = '01.05.2005'))inherits (payment);
create table payment_06_2005
(check (DATE_TRUNC('month', payment_date) = '01.06.2005'))inherits (payment);
create table payment_07_2005
(check (DATE_TRUNC('month', payment_date) = '01.07.2005'))inherits (payment);
create table payment_08_2005
(check (DATE_TRUNC('month', payment_date) = '01.08.2005'))inherits (payment);

---������� �������
CREATE INDEX payment_05_2005_date_idx ON payment_05_2005 (CAST(payment_date as date));
CREATE INDEX payment_06_2005_date_idx ON payment_06_2005 (CAST(payment_date as date));
CREATE INDEX payment_07_2005_date_idx ON payment_07_2005 (CAST(payment_date as date));
CREATE INDEX payment_08_2005_date_idx ON payment_08_2005 (CAST(payment_date as date));

--- ������� ������� �������������� � ������������ ��������
-- �� insert
CREATE RULE payment_insert_05_2005 AS ON INSERT TO payment WHERE (DATE_TRUNC('month', payment_date) = '01.05.2005')DO INSTEAD INSERT INTO payment_05_2005 VALUES (new.*);
CREATE RULE payment_insert_06_2005 AS ON INSERT TO payment WHERE (DATE_TRUNC('month', payment_date) = '01.06.2005')DO INSTEAD INSERT INTO payment_06_2005 VALUES (new.*);
CREATE RULE payment_insert_07_2005 AS ON INSERT TO payment WHERE (DATE_TRUNC('month', payment_date) = '01.07.2005')DO INSTEAD INSERT INTO payment_07_2005 VALUES (new.*);
CREATE RULE payment_insert_08_2005 AS ON INSERT TO payment WHERE (DATE_TRUNC('month', payment_date) = '01.08.2005')DO INSTEAD INSERT INTO payment_08_2005 VALUES (new.*);
--���� ��������
DROP RULE payment_insert_05_2005 ON payment;
--������ ����� ��������� ������ �� ������������ ������� � �������� � ������������� ��������� �� �����.
WITH cte AS ( 
DELETE FROM ONLY payment 
WHERE DATE_TRUNC('month', payment_date) = '01.05.2005' 
RETURNING *)
INSERT INTO payment_05_2005 
SELECT * FROM cte;

WITH cte AS ( 
DELETE FROM ONLY payment 
WHERE DATE_TRUNC('month', payment_date) = '01.06.2005' 
RETURNING *)
INSERT INTO payment_06_2005 
SELECT * FROM cte;

WITH cte AS ( 
DELETE FROM ONLY payment 
WHERE DATE_TRUNC('month', payment_date) = '01.07.2005' 
RETURNING *)
INSERT INTO payment_07_2005 
SELECT * FROM cte;

WITH cte AS ( 
DELETE FROM ONLY payment 
WHERE DATE_TRUNC('month', payment_date) = '01.08.2005' 
RETURNING *)
INSERT INTO payment_08_2005 
SELECT * FROM cte;


--������� ����������

--������ - ��� ���� ������� �������������, �� ����� ���� ��� ���������� ������ ������� � ������������ �������, � ��� ���� ��������� � ������ ��������
CREATE RULE payment_update_05_2005 AS ON UPDATE TO payment 
WHERE (DATE_TRUNC('month', new.payment_date) != '01.05.2005' 
	AND DATE_TRUNC('month', new.payment_date) = '01.06.2005')
DO INSTEAD (INSERT INTO payment VALUES (new.*); 
	DELETE FROM payment_05_2005 WHERE payment_id = new.payment_id);
	
CREATE RULE payment_update_05_2005 AS ON UPDATE TO payment 
WHERE (DATE_TRUNC('month', new.payment_date) != '01.05.2005' 
	AND DATE_TRUNC('month', new.payment_date)in('01.06.2005', '01.07.2005','01.08.2005'))
DO INSTEAD (INSERT INTO payment VALUES (new.*); 
	DELETE FROM payment_05_2005 WHERE payment_id = new.payment_id);
	
update payment
set payment_date = '2005-06-25 11:30:37'
where payment_id = 1

--- ������ � ���������� � ����������

--������� public
--��������������� �� �������� �����
--������� ��������  � �������
-- ������� �������
CREATE TRIGGER payment_insert_tg
BEFORE insert ON payment
FOR EACH ROW EXECUTE FUNCTION payment_insert_tg();
--������� ���������� �-�
CREATE OR REPLACE FUNCTION payment_insert_tg() RETURNS TRIGGER AS $$
BEGIN
	IF DATE_TRUNC('month', new.payment_date) = '01.05.2005' THEN    
		INSERT INTO payment_05_2005 VALUES (new.*);
	ELSIF DATE_TRUNC('month', new.payment_date) = '01.06.2005' THEN  
		INSERT INTO payment_06_2005 VALUES (new.*);
	ELSIF DATE_TRUNC('month', new.payment_date) = '01.07.2005' THEN  
		INSERT INTO payment_07_2005 VALUES (new.*);
	ELSIF DATE_TRUNC('month', new.payment_date) = '01.08.2005' THEN  
		INSERT INTO payment_08_2005 VALUES (new.*);
	ELSE RAISE EXCEPTION '����������� ��������';
	END IF;
	RETURN NULL;
END; $$ LANGUAGE plpgsql;

create temporary table old_payment as (select * from payment p)
INSERT INTO payment 
SELECT * FROM old_payment;

--- ���������� �-� � ��������� ����������� ������

CREATE OR REPLACE FUNCTION payment_insert_tg() RETURNS TRIGGER AS $$
DECLARE new_month date; new_month_part text; partition_table_name text; tg_name text;
begin
	new_month = DATE_TRUNC('month', new.payment_date)::date; --2005-06-01
	new_month_part = CONCAT(SPLIT_PART(new_month::text, '-', 2), '_', SPLIT_PART(new_month::text, '-', 1));--06_2005
	partition_table_name = FORMAT('payment_%s', new_month_part);--payment_06_2005
	tg_name = FORMAT('update_%s_tg', partition_table_name);
	IF (TO_REGCLASS(partition_table_name) IS NULL) then
		EXECUTE FORMAT(
			'CREATE TABLE %I ('
	    	'  CHECK (DATE_TRUNC(''month'', payment_date) = %L)'
	    	') INHERITS (payment);'
	    	, partition_table_name, new_month);
	    EXECUTE FORMAT(
			'CREATE INDEX %1$s_date_idx ON %1$I (CAST(payment_date as date));'
			, partition_table_name);
		EXECUTE FORMAT(
			'CREATE TRIGGER %I
			BEFORE UPDATE ON %I
			FOR EACH ROW EXECUTE FUNCTION payment_update_tg();', tg_name, partition_table_name);
	END IF;
	EXECUTE FORMAT('INSERT INTO %I VALUES ($1.*)', partition_table_name) USING NEW;
	RETURN NULL;
end;
$$ LANGUAGE plpgsql;
---���������� �-� �� updatte ��������
CREATE OR REPLACE FUNCTION payment_update_tg() RETURNS TRIGGER AS $$
declare id int = new.payment_id;
begin
	if DATE_TRUNC('month', old.payment_date) != DATE_TRUNC('month', new.payment_date)
		then 
			EXECUTE 'INSERT INTO "payment" VALUES ($1.*)' USING NEW;
			execute 'delete from ' || quote_ident(tg_table_name) || ' where payment_id = ' || id;
		RETURN null;
	else 
		RETURN new;
	end if;
end;
$$ LANGUAGE plpgsql;

-- ������������ - ���������� �� ������ ��������
-- ������� 2 �� payment2005, payment 2006
create database payment_2005;
create database payment_2006;
set search_path to payment_2005;
CREATE TABLE payment (
	payment_id int NOT NULL,
	customer_id int2 NOT NULL,
	staff_id int2 NOT NULL,
	rental_id int4 NOT NULL,
	amount numeric(5, 2) NOT NULL,
	payment_date timestamp NOT null check(Date_part('year', payment_date)=2005))

create index payment_date_idx on payment (DATE_PART('year', payment_date));	
	
set search_path to payment_2006;
CREATE TABLE payment (
	payment_id int NOT NULL,
	customer_id int2 NOT NULL,
	staff_id int2 NOT NULL,
	rental_id int4 NOT NULL,
	amount numeric(5, 2) NOT NULL,
	payment_date timestamp NOT null check(Date_part('year', payment_date)=2006));

create index payment_date_idx on payment (DATE_PART('year', payment_date));
-- ������� ���������� postgres_fdw
create extension postgres_fdw
-- ������� ������� �������
CREATE SERVER payment_2005_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'localhost', port '5432', dbname 'payment_2005');
-- ������ ������� ������������
CREATE USER MAPPING FOR postgres
SERVER payment_2005_server
OPTIONS (user 'postgres', password '123');
-- ������� ������� �������
CREATE SERVER payment_2006_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'localhost', port '5432', dbname 'payment_2006');
-- ������ ������� ������������
CREATE USER MAPPING FOR postgres
SERVER payment_2006_server
OPTIONS (user 'postgres', password '123');
--������� ������� �������
CREATE FOREIGN TABLE payment_2005 (
	payment_id int NOT NULL,
	customer_id int2 NOT NULL,
	staff_id int2 NOT NULL,
	rental_id int NOT NULL,
	amount numeric(5, 2) NOT NULL,
	payment_date timestamp NOT NULL) 
INHERITS (payment)
SERVER payment_2005_server
OPTIONS (schema_name 'public', table_name 'payment');
--������� ������� �������
CREATE FOREIGN TABLE payment_2006 (
	payment_id int NOT NULL,
	customer_id int2 NOT NULL,
	staff_id int2 NOT NULL,
	rental_id int NOT NULL,
	amount numeric(5, 2) NOT NULL,
	payment_date timestamp NOT NULL) 
INHERITS (payment)
SERVER payment_2006_server
OPTIONS (schema_name 'public', table_name 'payment');

--��������� ��� �� �� �������, �� ����������� �� ������ �� �� ������ ��������
-- ����� ������� � ���������� �-� ���� ������������ ������
CREATE OR REPLACE FUNCTION payment_insert_tg() RETURNS TRIGGER AS $$
BEGIN
	IF DATE_PART('year', new.payment_date) = 2005 THEN    
		INSERT INTO payment_2005 VALUES (new.*);
	ELSIF DATE_PART('year', new.payment_date) = 2006 THEN  
		INSERT INTO payment_2006 VALUES (new.*);
	ELSE RAISE EXCEPTION '����������� ��������';
	END IF;
	RETURN NULL;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER payment_insert_tg    
BEFORE INSERT ON payment
FOR EACH ROW EXECUTE FUNCTION payment_insert_tg();
--����� ��������� ������ �� �������� �� ������������ �������
WITH cte AS (  
    DELETE FROM ONLY payment      
    WHERE DATE_PART('year', payment_date) = 2005 RETURNING *)
INSERT INTO payment_2005   
    SELECT * FROM cte;
   
WITH cte AS (  
    DELETE FROM ONLY payment      
    WHERE DATE_PART('year', payment_date) = 2006 RETURNING *)
INSERT INTO payment_2006   
    SELECT * FROM cte;





