/*************************************************************************************************
Модуль 5. Домашнее задание по теме "«PostgreSQL Extensions"
**************************************************************************************************
Задание 1. 
Создайте подключение к удаленному облачному серверу базы HR (база данных postgres, схема hr),
 используя модуль postgres_fdw.
Напишите SQL-запрос на выборку любых данных используя 2 сторонних таблицы, соединенных с помощью JOIN.
В качестве ответа на задание пришлите список команд, использовавшихся для настройки подключения, 
создания внешних таблиц, а также получившийся SQL-запрос.
**************************************************************************************************/
--Создаем отдельную БД для расширений
create database osm;

-- Создаем отдельную схемy
CREATE SCHEMA extensions AUTHORIZATION postgres;

-- Задаем путь для поиска
set search_path to extensions;

--устанавливаем расширение postgres_fdw
create extension postgres_fdw;

--создаем внешний сервер с именем foreign_server, работающий через postgres_fdw
-- в опциям прописываем хост, порт и название БД, к которой хотим подключиться
-- в системных объектах  внашей схеме (extensions в бд HR) появляются postgres_fdw В оболочках внешних данных 
-- и foreign server в серверах удаленного доступа 

create server foreign_server
foreign data wrapper postgres_fdw
options(host '51.250.106.132', port '19001', dbname 'postgres');

--Для определения роли, которая будет задействована на удалённом сервере, задаётся сопоставление пользователей
--postgres На локальном сервере, netology - на удаленном
CREATE USER MAPPING FOR postgres 
SERVER foreign_server OPTIONS (user 'netology', password 'NetoSQL2019');

--создаем внешнюю таблицу 1,при этом атрибуты должны иметь идентичные свойства и типы данных, как и в таблице на внешнем сервере

CREATE FOREIGN TABLE address (
address_id int4,
full_address text,
city_id int4,
postal_code text)
SERVER foreign_server
OPTIONS (schema_name 'hr', table_name 'address');-- здесь схема в которой находится таблица в облаке, и имя этой таблицы
select * from in_table_address;

----создаем внешнюю таблицу 2

CREATE FOREIGN TABLE city (
city_id int4,
city text)
SERVER foreign_server
OPTIONS (schema_name 'hr', table_name 'city');
select * from in_table_city;
 
--запрос к внешним таблицам - внутри функции

create or REPLACE function p1(in  text, out "Индекс" text,out "Адрес кандидата" text) returns  setof record  as $$
begin
return query
		select a.postal_code as "Индекс", a.full_address as "Адрес кандидата"
		from address a
		join city c using(city_id)
	where c.city = $1;
END;
$$ LANGUAGE plpgsql;
select * from p1('Москва');

--так тоже можно было, но тогда трабл с типами переменных у почтового индекса
IMPORT FOREIGN SCHEMA hr LIMIT TO (address, city) 
FROM SERVER foreign_server
INTO extensions;

--заметаем следы:

-- удалить функцию
drop function p1;

--удалить обертку
drop user mapping for postgres server foreign_server;

--удалить внешний сервер вместе с внешними таблицами
drop server foreign_server cascade;

-- удалить расширение
drop extension postgres_fdw;

--удалить схему extensions 

drop SCHEMA extensions;
set search_path to public;
