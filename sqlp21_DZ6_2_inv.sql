-- Задание 2
--создаем новую базу данных
create database inv owner ='postgres';

--создаем 2 таблицы и индексы к ним
CREATE TABLE inventory_01 (
	inventory_id int4 NOT NULL,
	film_id int2 NOT NULL,
	store_id int2 NOT NULL,
	last_update timestamp NOT NULL DEFAULT now(),
	CONSTRAINT inventory_01_store_id_check CHECK ((store_id = 1))
);
CREATE INDEX inventory_01_idx ON inventory_01 (cast(store_id as int4));

CREATE TABLE inventory_02 (
	inventory_id int4 NOT NULL,
	film_id int2 NOT NULL,
	store_id int2 NOT NULL,
	last_update timestamp NOT NULL DEFAULT now(),
	CONSTRAINT inventory_01_store_id_check CHECK ((store_id = 2))
);

CREATE INDEX inventory_02_idx ON inventory_02 (cast(store_id as int4));
select * from inventory_01;
select * from inventory_02;




