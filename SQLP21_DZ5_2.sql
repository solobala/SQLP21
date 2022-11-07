/*************************************************************************************************
������ 5. �������� ������� �� ���� "�PostgreSQL Extensions"
**************************************************************************************************
������� 2. 
� ������� ������ tablefunc �������� �� ������� projects ���� HR ������� � �������, 
��������� ������� �����: ���, ������ � ������ �� �������, ����� ���� �� ��������� ���� �������� �� ���.
� �������� ������ �� ������� �������� ������������ SQL-������.
��������� ���������: letsdocode.ru...lp-5-2.png
**************************************************************************************************/
set search_path to hr;
-- ������� ���������� ��� ������� �� �������� ���������
create extension tablefunc;

 -- 1. �������, ������� ��� ����������� ������� �� ������� �� ������ ��� ������ �� ������� � projects
select  DATE_TRUNC('year', created_at) as years,count(distinct DATE_TRUNC('month', created_at)) as monthes
FROM projects
group by 1;

-- 2. ������� ������ �� ������� ��� ������
SELECT DATE_PART('years', created_at) as year_ ,DATE_PART('month', created_at) as month_, SUM(amount) as sum
FROM projects
group by 1,2
order by 1,2

--� �������
SELECT DATE_PART('years', created_at) as year_ ,DATE_PART('month', created_at) as month_, SUM(amount) as sum
FROM projects
group by cube(1,2)
order by 1,2

-- ������ ������� �������
select * from crosstab ($$ 
select year_::text, coalesce(m::text, '�����'), sum_ from(
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
select '�����'
)
$$
)  as cst("���" text, 
"������" numeric, 
"�������" numeric,  
"����" numeric, 
"������" numeric,  
"���" numeric, 
"����" numeric,
"����" numeric,
"������" numeric,
"��������" numeric,
"�������" numeric,
"������" numeric,
"�������" numeric,
"�����" numeric);

-- �������� ����. ���� ��� ������ ������� �������
create TYPE crosstab_numeric_12_cols AS (
"���" numeric,"������" numeric,
"�������" numeric,
"����" numeric,
"������" numeric,
"���" numeric,
"����" numeric,
"����" numeric,
"������" numeric,
"��������" numeric,
"�������" numeric,
"������" numeric,
"�������" numeric,
"�����" numeric);

-- �-�,  ������� ������� ��������� ���������� ����
CREATE OR REPLACE FUNCTION crosstab_numeric_12_cols(text,text)
RETURNS setof crosstab_numeric_12_cols
AS '$libdir/tablefunc','crosstab_hash' LANGUAGE C STABLE STRICT;

--������ ��� ������ ������� ������� � �������������� �������
select * from crosstab_numeric_12_cols ($$ 
select year_::text, coalesce(m::text, '�����'), sum_ from(
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
select '�����'
)
$$);

