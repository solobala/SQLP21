/*************************************************************************************************
������ 5. �������� ������� �� ���� "�PostgreSQL Extensions"
**************************************************************************************************
������� 1. 
�������� ����������� � ���������� ��������� ������� ���� HR (���� ������ postgres, ����� hr),
 ��������� ������ postgres_fdw.
�������� SQL-������ �� ������� ����� ������ ��������� 2 ��������� �������, ����������� � ������� JOIN.
� �������� ������ �� ������� �������� ������ ������, ���������������� ��� ��������� �����������, 
�������� ������� ������, � ����� ������������ SQL-������.
**************************************************************************************************/
--������� ��������� �� ��� ����������
create database osm;

-- ������� ��������� ����y
CREATE SCHEMA extensions AUTHORIZATION postgres;

-- ������ ���� ��� ������
set search_path to extensions;

--������������� ���������� postgres_fdw
create extension postgres_fdw;

--������� ������� ������ � ������ foreign_server, ���������� ����� postgres_fdw
-- � ������ ����������� ����, ���� � �������� ��, � ������� ����� ������������
-- � ��������� ��������  ������ ����� (extensions � �� HR) ���������� postgres_fdw � ��������� ������� ������ 
-- � foreign server � �������� ���������� ������� 

create server foreign_server
foreign data wrapper postgres_fdw
options(host '51.250.106.132', port '19001', dbname 'postgres');

--��� ����������� ����, ������� ����� ������������� �� �������� �������, ������� ������������� �������������
--postgres �� ��������� �������, netology - �� ���������
CREATE USER MAPPING FOR postgres 
SERVER foreign_server OPTIONS (user 'netology', password 'NetoSQL2019');

--������� ������� ������� 1,��� ���� �������� ������ ����� ���������� �������� � ���� ������, ��� � � ������� �� ������� �������

CREATE FOREIGN TABLE address (
address_id int4,
full_address text,
city_id int4,
postal_code text)
SERVER foreign_server
OPTIONS (schema_name 'hr', table_name 'address');-- ����� ����� � ������� ��������� ������� � ������, � ��� ���� �������
select * from in_table_address;

----������� ������� ������� 2

CREATE FOREIGN TABLE city (
city_id int4,
city text)
SERVER foreign_server
OPTIONS (schema_name 'hr', table_name 'city');
select * from in_table_city;
 
--������ � ������� �������� - ������ �������

create or REPLACE function p1(in  text, out "������" text,out "����� ���������" text) returns  setof record  as $$
begin
return query
		select a.postal_code as "������", a.full_address as "����� ���������"
		from address a
		join city c using(city_id)
	where c.city = $1;
END;
$$ LANGUAGE plpgsql;
select * from p1('������');

--��� ���� ����� ����, �� ����� ����� � ������ ���������� � ��������� �������
IMPORT FOREIGN SCHEMA hr LIMIT TO (address, city) 
FROM SERVER foreign_server
INTO extensions;

--�������� �����:

-- ������� �������
drop function p1;

--������� �������
drop user mapping for postgres server foreign_server;

--������� ������� ������ ������ � �������� ���������
drop server foreign_server cascade;

-- ������� ����������
drop extension postgres_fdw;

--������� ����� extensions 

drop SCHEMA extensions;
set search_path to public;
