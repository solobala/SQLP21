/*************************************************************************************************
Модуль 5. Домашнее задание по теме Домашнее задание "Масштабирование"
**************************************************************************************************
Задание 1. 
Выполните горизонтальное партиционирование для таблицы inventory учебной базы dvd-rental:
	- создайте 2 партиции по значению store_id
	- создайте индексы для каждой партиции
	- заполните партиции данными из родительской таблицы
	- для каждой партиции создайте правила на внесение, обновление, удаление данных. 
Напишите команды SQL для проверки работы правил.
**************************************************************************************************/
set search_path to public;
--Это родительская таблица, откуда делаем партиционирование store_id  - определяем к-во партиций
select distinct store_id from inventory;
-- удаляем ограничения внешнего ключа rental_inventory_id_fkey из rental
alter table rental drop constraint rental_inventory_id_fkey;
-- удаляем представления, которые связаны с родительской таблицей
drop view sales_by_film_category;
drop view sales_by_store;
--создаем партиции
create table inventory_01 (check (store_id =1))inherits (inventory);
create table inventory_02 (check (store_id =2))inherits (inventory);
---создаем индексы
CREATE INDEX inventory_01_idx ON inventory_01 (CAST(store_id as int4));
CREATE INDEX inventory_02_idx ON inventory_02 (CAST(store_id as int4));
--- создаем правила взаимодействия с родительской таблицей
-- на insert
CREATE RULE inventory_insert_01 AS ON INSERT TO inventory WHERE (store_id = 1)DO INSTEAD INSERT INTO inventory_01 VALUES (new.*);
CREATE RULE inventory_insert_02 AS ON INSERT TO inventory WHERE (store_id = 2)DO INSTEAD INSERT INTO inventory_02 VALUES (new.*);
-- на update
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
-- На delete не нужно правило, и так все работает, см. тест ниже
-- переносим данные из родительской таблицы в партиции с одновременным удалением из родит.
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
-- проверяем содержимое родительской таблицы и партиций
SELECT * FROM ONLY inventory;
select * from inventory_01;
select * from inventory_02;
-- восстановим удаленные ранее представления sales_by_film_category и sales_by_store
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
 
-- вместо удаленного ограничение  внешнего ключа rental_inventory_id_fkey в rental 
-- следует написать триггер и триггерную функцию к нему для последующего контроля целостности данных ( в задание не входит)

--тест на внесение данных в партиции 1 и 2
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

--тест на обновление данных в партицию 1
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

--тест на обновление данных в партиции 2
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

--тест на delete
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
 * Задание 2. 
 * Создайте новую базу данных и в ней 2 таблицы для хранения данных по инвентаризации каждого магазина, 
 * которые будут наследоваться из таблицы inventory базы dvd-rental. 
 * Используя шардирование и модуль postgres_fdw, создайте подключение к новой базе данных и
 * необходимые внешние таблицы в родительской базе данных для наследования. 
 * Распределите данные по внешним таблицам. Напишите SQL-запросы для проверки работы внешних таблиц.

В качестве ответов на задания пришлите текст команд, использовавшихся для выполнения задания, 
и скриншоты рабочей области с получившимися партициями, внешними таблицами, SQL-запросами и их результатами.
************************************************************************************************************/
--удаляем схему public в таблице postgres, в которой делали предыдущее задание, и восстанавливаем ее
--устанавливаем расширение
select * from pg_available_extensions where installed_version is not null;
create extension postgres_fdw;
-- создаем внешний сервер
create server inv_server
foreign data wrapper postgres_fdw
options(host 'localhost', port '5432', dbname 'inv');

--сопоставление пользователей
CREATE USER MAPPING FOR postgres --имя пользователя на локальном сервере
SERVER inv_server OPTIONS (user 'postgres', password '2305623056');

--создаем внешние таблицы, которые наследуют от родительской
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
	ELSE RAISE EXCEPTION 'Отсутствует партиция';
	END IF;
	RETURN NULL;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER inventory_insert_tg    
BEFORE INSERT ON inventory
FOR EACH ROW EXECUTE FUNCTION inventory_insert_tg();

-- удаляем ограничения внешнего ключа rental_inventory_id_fkey из rental
alter table rental drop constraint rental_inventory_id_fkey;
-- удаляем представления, которые связаны с родительской таблицей
drop view sales_by_film_category;
drop view sales_by_store;
-- переносим данные из родительской таблицы во внешние таблицы с одновременным удалением из родит.
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
-- восстанавливаем удаленные представления
-- восстановим удаленные ранее представления sales_by_film_category и sales_by_store
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
 
-- вместо удаленного ограничение  внешнего ключа rental_inventory_id_fkey в rental 
-- следует написать триггер и триггерную функцию к нему для последующего контроля целостности данных ( в задание не входит)
