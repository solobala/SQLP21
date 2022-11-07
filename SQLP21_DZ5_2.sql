/*************************************************************************************************
Модуль 5. Домашнее задание по теме "«PostgreSQL Extensions"
**************************************************************************************************
Задание 2. 
С помощью модуля tablefunc получите из таблицы projects базы HR таблицу с данными, 
колонками которой будут: год, месяцы с января по декабрь, общий итог по стоимости всех проектов за год.
В качестве ответа на задание пришлите получившийся SQL-запрос.
Ожидаемый результат: letsdocode.ru...lp-5-2.png
**************************************************************************************************/
set search_path to hr;
-- создаем расширение для рабботы со сводными таблицами
create extension tablefunc;

 -- 1. смотрим, сколько нам понадобится колонок по месяцам за каждый год исходя из записей в projects
select  DATE_TRUNC('year', created_at) as years,count(distinct DATE_TRUNC('month', created_at)) as monthes
FROM projects
group by 1;

-- 2. Считаем оборот по месяцам без итогов
SELECT DATE_PART('years', created_at) as year_ ,DATE_PART('month', created_at) as month_, SUM(amount) as sum
FROM projects
group by 1,2
order by 1,2

--с итогами
SELECT DATE_PART('years', created_at) as year_ ,DATE_PART('month', created_at) as month_, SUM(amount) as sum
FROM projects
group by cube(1,2)
order by 1,2

-- запрос сводной таблицы
select * from crosstab ($$ 
select year_::text, coalesce(m::text, 'Итого'), sum_ from(
select 
coalesce(t2.y, year_) as year_,
t2.m,
coalesce(t.sum,0) as sum_
from(
	SELECT DATE_PART('years', created_at) as year_ ,
			DATE_PART('month', created_at) as month_, 
			SUM(amount) as sum
	FROM projects
	group by cube(1,2)
	order by 1,3
	)t
full join
(select y , m  from generate_series(2018,2020,1) y, generate_series(1,12,1) m order by 1,2) t2 
on t.year_=t2.y and  t.month_::int =t2.m
where coalesce(t2.y, year_) is not null
order by 1,2)p
$$,
$$
(select month_::text from
	(
	select distinct DATE_PART('month',
					DATE_TRUNC('month', created_at)) as month_ 
					from projects order by 1
	)q
union all
select 'Итого'
)
$$
)  as cst("Год" text, 
"Январь" numeric, 
"Февраль" numeric,  
"Март" numeric, 
"Апрель" numeric,  
"Май" numeric, 
"Июнь" numeric,
"Июль" numeric,
"Август" numeric,
"Сентябрь" numeric,
"Октябрь" numeric,
"Ноябрь" numeric,
"Декабрь" numeric,
"Итого" numeric);

-- Создание спец. типа для вывода сводной таблицы
create TYPE crosstab_numeric_12_cols AS (
"Год" numeric,"Январь" numeric,
"Февраль" numeric,
"Март" numeric,
"Апрель" numeric,
"Май" numeric,
"Июнь" numeric,
"Июль" numeric,
"Август" numeric,
"Сентябрь" numeric,
"Октябрь" numeric,
"Ноябрь" numeric,
"Декабрь" numeric,
"Итого" numeric);

-- ф-я,  которая выводит результат созданного типа
CREATE OR REPLACE FUNCTION crosstab_numeric_12_cols(text,text)
RETURNS setof crosstab_numeric_12_cols
AS '$libdir/tablefunc','crosstab_hash' LANGUAGE C STABLE STRICT;

--запрос для вывода сводной таблицы с использованием функции
select * from crosstab_numeric_12_cols ($$ 
select year_::text, coalesce(m::text, 'Итого'), sum_ from(
select 
coalesce(t2.y, year_) as year_,
t2.m,
coalesce(t.sum,0) as sum_
from(
	SELECT DATE_PART('years', created_at) as year_ ,
			DATE_PART('month', created_at) as month_, 
			SUM(amount) as sum
	FROM projects
	group by cube(1,2)
	order by 1,3
	)t
full join
(select y , m  from generate_series(2018,2020,1) y, generate_series(1,12,1) m order by 1,2) t2 
on t.year_=t2.y and  t.month_::int =t2.m
where coalesce(t2.y, year_) is not null
order by 1,2)p
$$
,
$$
(select month_::text from
	(
	select distinct DATE_PART('month',
					DATE_TRUNC('month', created_at)) as month_ 
					from projects order by 1
	)q
union all
select 'Итого'
)
$$);

