/*************************************************************************************************
������ 5. �������� ������� �� ���� �������� ������� "���������������"
**************************************************************************************************
������� 1. 
��������� �������������� ����������������� ��� ������� inventory ������� ���� dvd-rental:
	- �������� 2 �������� �� �������� store_id
	- �������� ������� ��� ������ ��������
	- ��������� �������� ������� �� ������������ �������
	- ��� ������ �������� �������� ������� �� ��������, ����������, �������� ������. 
�������� ������� SQL ��� �������� ������ ������.
**************************************************************************************************/
set search_path to public;
--��� ������������ �������, ������ ������ ����������������� store_id  - ���������� �-�� ��������
select distinct store_id from inventory;
-- ������� ����������� �������� ����� rental_inventory_id_fkey �� rental
alter table rental drop constraint rental_inventory_id_fkey;
-- ������� �������������, ������� ������� � ������������ ��������
drop view sales_by_film_category;
drop view sales_by_store;
--������� ��������
create table inventory_01 (check (store_id =1))inherits (inventory);
create table inventory_02 (check (store_id =2))inherits (inventory);
---������� �������
CREATE INDEX inventory_01_idx ON inventory_01 (CAST(store_id as int4));
CREATE INDEX inventory_02_idx ON inventory_02 (CAST(store_id as int4));
--- ������� ������� �������������� � ������������ ��������
-- �� insert
CREATE RULE inventory_insert_01 AS ON INSERT TO inventory WHERE (store_id = 1)DO INSTEAD INSERT INTO inventory_01 VALUES (new.*);
CREATE RULE inventory_insert_02 AS ON INSERT TO inventory WHERE (store_id = 2)DO INSTEAD INSERT INTO inventory_02 VALUES (new.*);
-- �� update
CREATE RULE inventory_update_01 AS ON UPDATE TO inventory 
WHERE (new.store_id != 1 
	AND new.store_id = 2)
DO INSTEAD (INSERT INTO inventory VALUES (new.*); 
	DELETE FROM inventory_01 WHERE inventory_id = new.inventory_id);
CREATE RULE inventory_update_02 AS ON UPDATE TO inventory 
WHERE (new.store_id != 2 
	AND new.store_id = 1)
DO INSTEAD (INSERT INTO inventory VALUES (new.*); 
DELETE FROM inventory_02 WHERE inventory_id = new.inventory_id);
-- �� delete �� ����� �������, � ��� ��� ��������, ��. ���� ����
-- ��������� ������ �� ������������ ������� � �������� � ������������� ��������� �� �����.
WITH cte1 AS ( 
DELETE FROM ONLY inventory 
WHERE store_id=1 
RETURNING *)
INSERT INTO inventory_01 
SELECT * FROM cte1;
WITH cte2 AS ( 
DELETE FROM ONLY inventory 
WHERE store_id=2 
RETURNING *)
INSERT INTO inventory_02 
SELECT * FROM cte2;
-- ��������� ���������� ������������ ������� � ��������
SELECT * FROM ONLY inventory;
select * from inventory_01;
select * from inventory_02;
-- ����������� ��������� ����� ������������� sales_by_film_category � sales_by_store
CREATE OR REPLACE VIEW public.sales_by_film_category
AS SELECT c.name AS category,
    sum(p.amount) AS total_sales
   FROM payment p
     JOIN rental r ON p.rental_id = r.rental_id
     JOIN inventory i ON r.inventory_id = i.inventory_id
     JOIN film f ON i.film_id = f.film_id
     JOIN film_category fc ON f.film_id = fc.film_id
     JOIN category c ON fc.category_id = c.category_id
  GROUP BY c.name
  ORDER BY (sum(p.amount)) DESC;
CREATE OR REPLACE VIEW public.sales_by_store
AS SELECT (c.city::text || ','::text) || cy.country::text AS store,
    (m.first_name::text || ' '::text) || m.last_name::text AS manager,
    sum(p.amount) AS total_sales
   FROM payment p
     JOIN rental r ON p.rental_id = r.rental_id
     JOIN inventory i ON r.inventory_id = i.inventory_id
     JOIN store s ON i.store_id = s.store_id
     JOIN address a ON s.address_id = a.address_id
     JOIN city c ON a.city_id = c.city_id
     JOIN country cy ON c.country_id = cy.country_id
     JOIN staff m ON s.manager_staff_id = m.staff_id
  GROUP BY cy.country, c.city, s.store_id, m.first_name, m.last_name
  ORDER BY cy.country, c.city;
 
-- ������ ���������� �����������  �������� ����� rental_inventory_id_fkey � rental 
-- ������� �������� ������� � ���������� ������� � ���� ��� ������������ �������� ����������� ������ ( � ������� �� ������)

--���� �� �������� ������ � �������� 1 � 2
begin;
select * from only inventory ;
select * from inventory where inventory_id = (select max(inventory_id) from inventory);
savepoint mysavepoint1;
insert into inventory(film_id,store_id,last_update)values(1000, 1, now());
savepoint mysavepoint2;
insert into inventory(film_id,store_id,last_update)values(999, 2, now());
savepoint mysavepoint2;
select * from only inventory ;
select * from inventory where inventory_id > 4581;
select * from inventory_01 where inventory_id = (select max(inventory_id) from inventory_01);
select * from inventory_02 where inventory_id = (select max(inventory_id) from inventory_02);
rollback to mysavepoint1;
commit;

--���� �� ���������� ������ � �������� 1
begin;
select * from inventory_01 where  inventory_id = 1;
savepoint mysavepoint1;
update inventory
set store_id = 2
where inventory_id = 1;
savepoint mysavepoint2;
select * from inventory_01 where  inventory_id = 1;
select * from inventory_02 where  inventory_id = 1;
rollback to mysavepoint1;
commit;

--���� �� ���������� ������ � �������� 2
begin;
select * from inventory_02 where  inventory_id = 5;
savepoint mysavepoint1;
update inventory
set store_id = 1
where inventory_id = 5;
savepoint mysavepoint2;
select * from inventory_02 where  inventory_id = 5;
select * from inventory_01 where  inventory_id = 5;
rollback to mysavepoint1;
commit;

--���� �� delete
begin;
select * from only inventory ;
select * from inventory where inventory_id in(1,5);
select * from inventory_01 where  inventory_id = 1;
select * from inventory_02 where  inventory_id = 5;
savepoint mysavepoint1;
delete from inventory where inventory_id in(1,5);
savepoint mysavepoint2;

select * from only inventory ;
select * from inventory where inventory_id in(1,5);
select * from inventory_01 where  inventory_id = 1;
select * from inventory_02 where  inventory_id = 5;
rollback to mysavepoint1;
commit;

/***********************************************************************************************************
 * ������� 2. 
 * �������� ����� ���� ������ � � ��� 2 ������� ��� �������� ������ �� �������������� ������� ��������, 
 * ������� ����� ������������� �� ������� inventory ���� dvd-rental. 
 * ��������� ������������ � ������ postgres_fdw, �������� ����������� � ����� ���� ������ �
 * ����������� ������� ������� � ������������ ���� ������ ��� ������������. 
 * ������������ ������ �� ������� ��������. �������� SQL-������� ��� �������� ������ ������� ������.

� �������� ������� �� ������� �������� ����� ������, ���������������� ��� ���������� �������, 
� ��������� ������� ������� � ������������� ����������, �������� ���������, SQL-��������� � �� ������������.
************************************************************************************************************/
--������� ����� public � ������� postgres, � ������� ������ ���������� �������, � ��������������� ��
--������������� ����������
select * from pg_available_extensions where installed_version is not null;
create extension postgres_fdw;
-- ������� ������� ������
create server inv_server
foreign data wrapper postgres_fdw
options(host 'localhost', port '5432', dbname 'inv');

--������������� �������������
CREATE USER MAPPING FOR postgres --��� ������������ �� ��������� �������
SERVER inv_server OPTIONS (user 'postgres', password '2305623056');

--������� ������� �������, ������� ��������� �� ������������
CREATE FOREIGN TABLE in_inventory_01 (
inventory_id int4 NOT NULL,
	film_id int2 NOT NULL,
	store_id int2 NOT NULL,
	last_update timestamp NOT NULL DEFAULT now(),
	CONSTRAINT inventory_01_store_id_check CHECK (store_id = 1))
	INHERITS(inventory)
SERVER inv_server
OPTIONS (schema_name 'public', table_name 'inventory_01');

CREATE FOREIGN TABLE in_inventory_02 (
inventory_id int4 NOT NULL,
	film_id int2 NOT NULL,
	store_id int2 NOT NULL,
	last_update timestamp NOT NULL DEFAULT now(),
	CONSTRAINT inventory_02_store_id_check CHECK (store_id = 2))
	INHERITS(inventory)
SERVER inv_server
OPTIONS (schema_name 'public', table_name 'inventory_02');

CREATE OR REPLACE FUNCTION inventory_insert_tg() RETURNS TRIGGER AS $$
BEGIN
	IF  new.store_id = 1 THEN    
		INSERT INTO in_inventory_01 VALUES (new.*);
	ELSIF new.store_id = 2 THEN  
		INSERT INTO in_inventory_02 VALUES (new.*);
	ELSE RAISE EXCEPTION '����������� ��������';
	END IF;
	RETURN NULL;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER inventory_insert_tg    
BEFORE INSERT ON inventory
FOR EACH ROW EXECUTE FUNCTION inventory_insert_tg();

-- ������� ����������� �������� ����� rental_inventory_id_fkey �� rental
alter table rental drop constraint rental_inventory_id_fkey;
-- ������� �������������, ������� ������� � ������������ ��������
drop view sales_by_film_category;
drop view sales_by_store;
-- ��������� ������ �� ������������ ������� �� ������� ������� � ������������� ��������� �� �����.
WITH cte1 AS (  
    DELETE FROM ONLY inventory      
    WHERE store_id =1  RETURNING *)
INSERT INTO in_inventory_01   
    SELECT * FROM cte1;
select * from in_inventory_01;
select * from only inventory;

WITH cte2 AS (  
    DELETE FROM ONLY inventory      
    WHERE store_id =2  RETURNING *)
INSERT INTO in_inventory_02   
    SELECT * FROM cte2;
select * from in_inventory_02;
select * from only inventory;
-- ��������������� ��������� �������������
-- ����������� ��������� ����� ������������� sales_by_film_category � sales_by_store
CREATE OR REPLACE VIEW public.sales_by_film_category
AS SELECT c.name AS category,
    sum(p.amount) AS total_sales
   FROM payment p
     JOIN rental r ON p.rental_id = r.rental_id
     JOIN inventory i ON r.inventory_id = i.inventory_id
     JOIN film f ON i.film_id = f.film_id
     JOIN film_category fc ON f.film_id = fc.film_id
     JOIN category c ON fc.category_id = c.category_id
  GROUP BY c.name
  ORDER BY (sum(p.amount)) DESC;
CREATE OR REPLACE VIEW public.sales_by_store
AS SELECT (c.city::text || ','::text) || cy.country::text AS store,
    (m.first_name::text || ' '::text) || m.last_name::text AS manager,
    sum(p.amount) AS total_sales
   FROM payment p
     JOIN rental r ON p.rental_id = r.rental_id
     JOIN inventory i ON r.inventory_id = i.inventory_id
     JOIN store s ON i.store_id = s.store_id
     JOIN address a ON s.address_id = a.address_id
     JOIN city c ON a.city_id = c.city_id
     JOIN country cy ON c.country_id = cy.country_id
     JOIN staff m ON s.manager_staff_id = m.staff_id
  GROUP BY cy.country, c.city, s.store_id, m.first_name, m.last_name
  ORDER BY cy.country, c.city;
 
-- ������ ���������� �����������  �������� ����� rental_inventory_id_fkey � rental 
-- ������� �������� ������� � ���������� ������� � ���� ��� ������������ �������� ����������� ������ ( � ������� �� ������)
