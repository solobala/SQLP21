
/***********************************************************************************************************
 * Домашнее задание "Зависимости. Нормализация. Денормализация"
 ***********************************************************************************************************
 * Необходимо нормализовать исходную таблицу.
 * Получившиеся отношения должны быть не ниже 3 Нормальной Формы.
 * В результате должна быть диаграмма из не менее чем 5 нормализованных отношений и 
 * 1 таблицы с историчностью, соответствующей требованиям SCD4.
 * Контролировать целостность данных в таблице с историчными данными необходимо с помощью триггерной функции.
 * Результат работы должен быть в виде одного скриншота ER-диаграммы и sql запроса с триггером и функцией.
 ***********************************************************************************************************/
commit;
create database if not exists DZ;
create schema if not exists DZ3_1;
set search_path to DZ3_1;

----------------------------Создаем таблицы - справочники, заносим в них информацию-------------------------
--department------------------------------------------------------------------------------------------------
CREATE TABLE if not exists department (
	department_id serial primary key,
	department_name varchar(50) NOT null,
	department_address varchar(250)
);
insert into department (department_name, department_address)
select * from unnest(
     array[
     	'Design',
		'Maintenance and Administration',
		'IT Help Desk',
		'Project Office',
		'Software Development'
	],
	array[
	'Bradford, 113 Meadow Freyaview W1D',
	'Bradford, 113 Meadow Freyaview W1D',
	'Birmingham, 625 Bailey Center RM12',
	'Birmingham, 625 Bailey Center RM12',
	'Birmingham, 625 Bailey Center RM12'
	]

); 
--position-------------------------------------------------------------------------------------------------
CREATE TABLE if not exists position (
	position_id serial primary key,
	position_name varchar(100) NOT null,
	department_id int4
);

insert into position(position_name, department_id)
select * from  unnest(
array[
    'Graphic Designer',
	'Web Designer',
	'Computer Programmer',
	'Project Manager',
	'Project Office Team Leader',
	'Web Application Developer',
	'Analyst'
],
array[
	(select department_id from department where department_name ='Design'),
	(select department_id from department where department_name ='Maintenance and Administration'),
	(select department_id from department where department_name ='IT Help Desk'),
	(select department_id from department where department_name ='Project Office'),
	(select department_id from department where department_name ='Maintenance and Administration'),
	(select department_id from department where department_name ='Software Development'),
	(select department_id from department where department_name ='Software Development')]);

--person----------------------------------------------------------------------------------------------------
CREATE TABLE if not exists person (
	person_id serial primary key,
	person_name varchar(50) NOT NULL,
	date_birth date, -- not null check (date_part('year', date_birth) > 1900), -- нельзя, т.к руководители тоже в таблице person, но по ним нет данных
	email varchar(50), --check ( email ~ '/.+\@.+\..+/') -- нельзя, т.к руководители тоже в таблице person, но по ним нет данных
	address varchar(250)
);

insert into person(person_name, date_birth, email, address) values
('Mary Roberts', '15.07.1975'::date, 'MaryRoberts@default.com','Bradford, 72 Shaw Land Lake Holly GL1'),
('Oscar Fowler', '01.11.1988'::date,  'OscarFowler@default.com','Birmingham, 8 Row West Tonytown BT60'),
('Everett Garcia', '22.05.1981'::date, 'EverettGarcia@default.com', 'Bradford, 40 Wood Isle Port BS4'),
('John Obrien',	'31.03.1978'::date,	'JohnObrien@default.com', 'Swansea, Studio 12 Way Lake M46'),
('Linda Smith', '07.07.1989'::date,	'LindaSmith@default.com','Birmingham, 63 Knight Corn East HU14'),
('Leon Mitchell', null, null, null),
('Sharon Hunter',null, null, null),
('David Morgan',null, null, null),
('William Lewis',null, null, null),
('Charles Johnson',null, null, null);

--supervisor------------------------------------------------------------------------------------------------
create table if not exists supervisor( 
supervisor_id serial primary key,
supervisor_name varchar(60),
person_id int
);


insert into supervisor(supervisor_name, person_id)
select * from unnest( 
	array[ 
	'Leon Mitchell',
	'Sharon Hunter',
	'David Morgan',
	'William Lewis',
	'Charles Johnson',
	'Everett Garcia'
	],
	array[6,7,8,9,10,3
	]
);

-----------------------------создаем связанные таблица ( один-ко многим)------------------------------------

--person_position------------------------------------------------------------------------------------------- 
create table if not exists person_position(
person_position_id serial primary key,
person_id int4,
position_id int4,
supervisor_id int4,
salary numeric(12,2),
effective_from date
);

insert into person_position (person_id, position_id, supervisor_id, salary, effective_from) values(
(select person_id from person where person_name = 'Mary Roberts'), 
(select position_id from position where position_name = 'Web Designer'),
(select supervisor_id from supervisor where supervisor_name = 'Everett Garcia'),
23500.,'2021-01-01'::date);

insert into person_position (person_id, position_id, supervisor_id, salary, effective_from) values(
(select person_id from person where person_name = 'Everett Garcia'), 
(select position_id from position where position_name = 'Project Office Team Leader'),
(select supervisor_id from supervisor where supervisor_name = 'William Lewis'),
27990.,'2018-12-18'::date);

insert into person_position (person_id, position_id, supervisor_id, salary, effective_from) values(
(select person_id from person where person_name = 'John Obrien'), 
(select position_id from position where position_name= 'Web Application Developer'),
(select supervisor_id from supervisor where supervisor_name = 'Charles Johnson'),
20100., '2021-05-31'::date);

--history_person_address-------------------------------------------------------------------------------------
CREATE TABLE if not exists history_person_address (
	history_person_address_id serial primary key,
	person_id int,
	old_person_address varchar(250),
	last_update timestamp default now()
);
insert into  history_person_address(person_id,old_person_address)
select * from unnest ( 
	array[13],
	array['Birmingham, 91 Davies Points New LU7']
);

--history_department_address----------------------------------------------------------------------------------
create table if not exists history_department_address (
history_department_address_id serial primary key,
	department_id int,
	old_department_address varchar(250),
	last_update timestamp default now()
);
insert into  history_department_address(department_id, old_department_address)
select * from unnest ( 
	array[5],
	array['Swansea, 557 Harbours New Sally BR6']
);
--history_position---------------------------------------------------------------------------------------------
create table if not exists history_position (
	history_person_position_id serial primary key,
	person_position_id int,
	person_id int,
	old_position_id int,
	old_supervisor_id int,
	old_salary numeric(12,2),
	date_begin date,
	date_end date,
	last_update timestamp default now()
);

insert into  history_position(person_id, old_position_id,old_supervisor_id, old_salary,date_begin,date_end )
select * from unnest ( 
	array[1,1,2,3,5,5],
	array[1,1,3,4,4,7],
	array[1,2,6,3,6,2],
	array[17000.,18500., 19700., 12000., 14600.,15900.],
	array['20.08.2017'::date, '21.02.2019'::date,'11.04.2018'::date, '30.06.2015'::date,'03.09.2016'::date, '13.11.2018'::date],
	array['31.01.2019'::date, '31.12.2020'::date,'27.03.2020'::date, '17.12.2018'::date,'12.11.2018'::date, '25.12.2020'::date]
);

-- Добавление внешних ключей-------------------------------------------------------------------------------------
alter table position 
add constraint position_department_id_fkey 
foreign key(department_id)  REFERENCES department(department_id);

alter table supervisor 
add  constraint supervisor_person_id_fkey 
FOREIGN KEY (person_id) REFERENCES person(person_id);

alter table person_position 
add constraint person_position_person_id_fkey 
foreign key(person_id) references person(person_id);

alter table person_position 
add constraint person_position_position_id_fkey 
foreign key(position_id) references position(position_id);

alter table person_position 
add constraint person_position_supervisor_id_fkey 
foreign key(supervisor_id) references supervisor(supervisor_id);

alter table history_person_address 
add constraint history_person_address_person_id_fkey 
foreign key(person_id) references person(person_id);

alter table history_department_address 
add constraint history_department_address_department_id_fkey 
foreign key(department_id) references department(department_id);

alter table history_position 
add constraint history_position_person_id_fkey 
foreign key(person_id) references person(person_id);

alter table history_position 
add constraint history_position_old_position_id_fkey 
foreign key(old_position_id) references position(position_id);

alter table history_position 
add constraint history_position_old_supervisor_id_fkey 
foreign key(old_supervisor_id) references supervisor(supervisor_id);

alter table history_position add column person_position_id int;
alter table history_position add constraint hp_id_fkey foreign key(person_position_id) references person_position(person_position_id);-- добавляем ограничение внешнего ключа 


-----------создание материализованного представления для просмотра всей информации по сотрудникам, включая архивную---------
create  view  all_person (
"Фамилия и имя сотрудника",
"Дата рождения",
"Адрес проживания",
"электронная почта",
"Должность",
"Департамент",
"Адрес департамента",
"Руководитель",
"Период работы", 
"Зарплата"
) as (
select 
	p.person_name as "Фамилия и имя сотрудника", 
	p.date_birth as "Дата рождения",
	p.address as "Адрес проживания", 
	p.email as "электронная почта", 
	ps.position_name  as "Должность", 
	d.department_name as "Департамент", 
	d.department_address  as "Адрес департамента", 
	s.supervisor_name as "Руководитель", 
	CONCAT(pp.effective_from,' - ', 'now')  as "Период работы",
	pp.salary as "Зарплата"
from person p
left join person_position pp using(person_id)
join position ps using (position_id)
join department d using(department_id)
left join supervisor s using(supervisor_id)
union all
select 
p.person_name as "Фамилия и имя сотрудника", 
p.date_birth as "Дата рождения", 
coalesce(hpa.old_person_address, (select address from person p where hp.person_id = p.person_id))  as "Адрес проживания", 
coalesce(p.email,(select email from person p where hp.person_id = p.person_id) )  as "электронная почта",
ps.position_name as "Должность", 
d.department_name  as "Департамент", 
coalesce(hda.old_department_address, 
(select department_address from department d2 where d2.department_id = d.department_id))  as "Адрес департамента",
s.supervisor_name  as "Руководитель", 
CONCAT(hp.date_begin, ' - ', hp.date_end) as "Период работы",
hp.old_salary as "Зарплата"
from person p
left join history_person_address hpa using(person_id)
left join history_position hp using(person_id)
left join position ps on hp.old_position_id = ps.position_id
left join department d using(department_id)
left join history_department_address hda using(department_id)
left join history_department_address hpd using(department_id)
left join supervisor s on hp.old_supervisor_id = s.supervisor_id
where s.supervisor_name is not null
order by 2);
select * from all_person;
commit;

---------------создание представления для просмотра информации по архиву-----------------------------------------------------
drop  view history_person;
create  view  history_person (
"Фамилия и имя сотрудника",
"Дата рождения",
"Адрес проживания",
"электронная почта",
"Должность",
"Департамент",
"Адрес департамента", 
"Руководитель",
"Период работы", 
"Зарплата"
) as (
select 
p.person_name,
p.date_birth,
coalesce(hpa.old_person_address, (select address from person p where hp.person_id = p.person_id)),
coalesce(p.email,(select email from person p where hp.person_id = p.person_id)) ,
ps.position_name, 
d.department_name, 
coalesce(hda.old_department_address, (select department_address from department d2 where d2.department_id = d.department_id)),
s.supervisor_name, 
CONCAT(hp.date_begin, ' - ', hp.date_end),
hp.old_salary
from person p
left join history_person_address hpa using(person_id)
left join history_position hp using(person_id)
left join position ps on hp.old_position_id = ps.position_id
left join department d using(department_id)
left join history_department_address hda using(department_id)
left join history_department_address hpd using(department_id)
left join supervisor s on hp.old_supervisor_id = s.supervisor_id
where s.supervisor_name is not null
order by 2);

select * from history_person;

-----------создание  представления для просмотра информации по актуальным сотрудникам-------------------------------------

create  view  actual_person (
"Фамилия и имя сотрудника",
"Дата рождения",
"Адрес проживания",
"электронная почта",
"Должность",
"Департамент",
"Адрес департамента", 
"Руководитель",
"Период работы", 
"Зарплата"
) as (
select 
	p.person_name, 
	p.date_birth,
	p.address, 
	p.email, 
	ps.position_name, 
	d.department_name, 
	d.department_address, 
	s.supervisor_name, 
	CONCAT(pp.effective_from,' - ', 'now'),
	pp.salary
from person p
left join person_position pp using(person_id)
join position ps using (position_id)
join department d using(department_id)
left join supervisor s using(supervisor_id)
order by 2);

select * from actual_person;

-------------Вспомогательные функции, используемые для проверки корректрости значений атрибутов, передаваемых в тригерные функции:--------------
-- check_position_id() - наличие position_id в таблице position,
-- check_supervisor_id() - наличие supervisor_id в таблице supervisor,
-- check_person_id() - наличие person_id в таблице person,
-- check_department_id() - наличие department_в таблице депарамент
-- check_person_id_in_history_person_address() - наличие person_id в таблице  history_person_address
-- check_department_id_in_history_department_address() - наличие depsrtment_id в таблице  history_department_address
-- check_person_position_id_in_history() - наличие записей для данного person_id по позиции с данным position_id в таблицe history_position

--check_position_id------------------------------------------------------------------------------------------------------------------------------
create or replace function check_position_id(int) returns text as $$
/*
 Вспомогательная ф-я, проверяющая наличие записей по позиции с данным position_id 
 в таблицe positions
 */
begin  
	if $1  IN (SELECT position_id FROM position ) then
		RETURN 'yes';
	else 
		return 'no';
	end if;
end;
$$LANGUAGE plpgsql;

--тесты
select check_position_id(1);---позиция есть в списке
select check_position_id(18);---позиция отсутствует в списке

--check_supervisor_id----------------------------------------------------------------------------------------------------------------------------
create or replace function check_supervisor_id(int) returns text as $$
/*
 Вспомогательная ф-я, проверяющая наличие записей по руководителю с данным supervisor_id 
 в таблицe supervisor
 */
begin  
	if $1  IN (SELECT supervisor_id FROM supervisor ) then
		RETURN 'yes';
	else 
		return 'no';
	end if;
end;
$$LANGUAGE plpgsql;

--тесты
select check_supervisor_id(1);---позиция есть в списке
select check_supervisor_id(18);---позиция отсутствует в списке

--check_person_id--------------------------------------------------------------------------------------------------------------------------------
create or replace function check_person_id(int) returns text as $$
/*
 Вспомогательная ф-я, проверяющая наличие записей по сотруднику с данным person_id 
 в таблицe person
 */
begin  
	if $1  IN (SELECT person_id FROM person) then
		RETURN 'yes';
	else 
		return 'no';
	end if;
end;
$$LANGUAGE plpgsql;

--тесты
select check_person_id(3);---позиция есть в списке
select check_person_id(18);---позиция отсутствует в списке

--check_department_id----------------------------------------------------------------------------------------------------------------------------
create or replace function check_department_id(int) returns text as $$
/*
 Вспомогательная ф-я, проверяющая наличие записей по департаменту с данным department_id 
 в таблицe history_department_address
 */
begin  
	if $1  IN (SELECT department_id FROM department group by 1) then
		RETURN 'yes';
	else 
		return 'no';
	end if;
end;
$$LANGUAGE plpgsql;

--тесты
select check_department_id(5);---позиция есть в списке
select check_department_id(18);---позиция отсутствует в списке

--check_person_id_in_history_person_address--------------------------------------------------------------------------------------------------------------------------------
create or replace function check_person_id_in_history_person_address(int) returns text as $$
/*
 Вспомогательная ф-я, проверяющая наличие записей по сотруднику с данным person_id 
 в таблицe history_person_address
 */
begin  
	if $1  IN (SELECT person_id FROM history_person_address group by 1) then
		RETURN 'yes';
	else 
		return 'no';
	end if;
end;
$$LANGUAGE plpgsql;

--тесты
select check_person_id_in_history_person_address(3);---позиция есть в истории
select check_person_id_in_history_person_address(18);---позиция отсутствует в истории

--check_department_id_in_history----------------------------------------------------------------------------------------------------------------------------
create or replace function check_department_id_in_history_department_address(int) returns text as $$
/*
 Вспомогательная ф-я, проверяющая наличие записей по департаменту с данным department_id 
 в таблицe history_department_address
 */
begin  
	if $1  IN (SELECT department_id FROM history_department_address group by 1) then
		RETURN 'yes';
	else 
		return 'no';
	end if;
end;
$$LANGUAGE plpgsql;

--тесты
select check_department_id_in_history_department_address(5);---позиция есть в истории
select check_department_id_in_history_department_address(1);---позиция отсутствует в истории

--check_person_position_id_in_history-----------------------------------------------------------------------------------------------------------------------
create or replace function check_person_position_id_in_history(int) returns text as $$
/*
 Вспомогательная ф-я, проверяющая наличие записей для данного person_id по позиции с данным position_id 
 в таблицe history_position
 */
begin  
	if $1  IN (SELECT person_position_id FROM history_position group by 1) then
		RETURN 'yes';
	else 
		return 'no';
	end if;
end;
$$LANGUAGE plpgsql;

--тесты
select check_person_position_id_in_history(1);---позиция есть в истории
select check_person_position_id_in_history(3);---позиция отсутствует в истории

----------------------------вспомогательные функции, используемые для получения значения атрибута или набора записей------------------------------------------------
-- get_old_salary();
-- get_old_person_address();
-- get_old_department_address();
-- get_department_address()
-- get_old_person_position()
-- current_person()
-- archive_person()

--get_old_salary---------------------------------------------------------------------------------------------------------------------------------
create or replace function get_old_salary(int,out old_salary_ numeric)  as $$
/*
 Вспомогательная ф-я, проверяющая наличие записей о зарплате сотрудника 
 в таблицe history_position
 и возвращающая предыдущую зарплату
 */
begin  
	select old_salary from history_position where person_id = $1 order by history_person_position_id desc limit 1 into old_salary_;
end;
$$LANGUAGE plpgsql;
--тесты
select get_old_salary(1);---позиция есть в истории
select get_old_salary(4);---позиция отсутствует в истории

--get_old_person_address-------------------------------------------------------------------------------------------------------------------------
create or replace function get_old_person_address(int, out old_person_address_ text)  as $$
/*
 Вспомогательная ф-я, проверяющая наличие записей об адресе сотрудника
 в таблицe history_person_address
 и возвращающая предыдущий адрес
 */
begin  
	select old_person_address from history_person_address where person_id = $1 order by history_person_address_id desc limit 1  into old_person_address_;
end;
$$LANGUAGE plpgsql;
--тесты
select get_old_person_address(3);---позиция есть в истории
select get_old_person_address(4);---позиция отсутствует в истории

--get_old_department_address---------------------------------------------------------------------------------------------------------------------
create or replace function get_old_department_address(int, out old_department_address_ text)  as $$
/*
 Вспомогательная ф-я, проверяющая наличие записей об адресе департамента
 в таблицe history_person_address
 и возвращающая предыдущий адрес
 */
begin  
	select old_department_address 
	from history_department_address 
	where department_id = $1 
	order by history_department_address_id desc 
	limit 1 into old_department_address_;
end;
$$LANGUAGE plpgsql;
--get_department_address---------------------------------------------------------------------------------------------------------------------
create or replace function get_department_address(int, out department_address_ text)  as $$
/*
 Вспомогательная ф-я, проверяющая наличие записей об адресе департамента
 в таблицe department
 и возвращающая текущий адрес по person_id
 */
begin  
	select distinct department_address 
	from person
	left join person_position using(person_id)
	left join position using(position_id)
	left join department using(department_id)
	where person_id = $1 
	into department_address_;
end;
$$LANGUAGE plpgsql;
--тесты
select get_old_department_address(5);---позиция есть в истории
select get_old_department_address(4);---позиция отсутствует в истории

select distinct department_address 
	from person
	left join person_position using(person_id)
	left join position using(position_id)
	left join department using(department_id)
	where person_id =2

--get_old_person_position-------------------------------------------------------------------------------------------------------------------------------

create or replace function get_old_person_position_id(int, out person_position_id_ int)  as $$
/*
 Вспомогательная ф-я, проверяющая наличие записей о позиции сотрудника 
 в таблицe history_position
 и возвращающая идентификатор предыдущей позиции;
 если позиция не изменялась, то возвращает идентификатор 
 */
begin  
	select position_id from history_position where person_id = $1 order by old_position_id desc limit 1  into person_position_id_;
end;
$$LANGUAGE plpgsql;

--тесты
select get_old_position_id(2);-- в истории - 1 запись по позиции сотрудника с идентификатором 2
select get_old_position_id(1);---позиции сотрудника с идентификатором 1 есть в истории, позиция не менялась, менялась зарплата
select get_old_position_id(5);---позиции сотрудника с идентификатором 5 есть в истории, позиция  менялась
select get_old_position_id(4);---позиция отсутствует в истории



------------------------------------------------Триггерные функции:------------------------------------------------------------------------------
-- person_address_updated();
-- department_address_updated();
-- person_position_updated();

--person_address_updated()------------------------------------------------------------------------------------------------------------------------

create or replace function person_address_updated() returns trigger as $$
/*
 * Триггерная функция срабатывает на обновление текущего адреса сотрудника. 
 */
declare last_updated timestamp;
old_person_address_ text;
begin
	last_updated = current_timestamp;
	old_person_address_= old.address;
   	insert into history_person_address(person_id, old_person_address, last_update) 
												values(new.person_id, old_person_address_, last_updated);
    return null;
end;
$$LANGUAGE plpgsql;	

--тест-----------------------------------------------------------------------------------------------------------------------------------------
begin;
savepoint mysavepoint1;

select person_name,address from person where person_id =1;
select person_name, old_person_address 
from person  join history_person_address 
using(person_id) where person_id =1;
update person set address = 'где-то там' where person_id = 1;

savepoint mysavepoint2;

select person_name,address from person where person_id =1;
select person_name, old_person_address 
from person  join history_person_address 
using(person_id) where person_id =1;
rollback to mysavepoint1;
commit;


--department_address_updated()---------------------------------------------------------------------------------------------------------------------
create or replace function department_address_updated() returns trigger as $$
/*
 * Триггерная функция срабатывает на обновление текущего адреса департамента
 */
declare last_updated timestamp;
old_department_address_ text;
begin

 	last_updated = current_timestamp;
 	old_department_address_ =old.department_address;
 	insert into history_department_address(department_id, old_department_address, last_update) 
												values(new.department_id, old_department_address_, last_updated);
    return null;
end;
$$LANGUAGE plpgsql;

--тест-------------------------------------------------------------------------------------------------------------------------------------------

begin;

savepoint mysavepoint1;

select department_name, department_address from department where department_id = 1;
select department_name, old_department_address 
from history_department_address
join department using(department_id)
where department_id = 1;
update department set department_address = 'где-то там' where department_id = 1;

savepoint mysavepoint2;

select department_name, department_address from department where department_id = 1;
select department_name, old_department_address 
from history_department_address
join department using(department_id)
where department_id = 1;
rollback to mysavepoint1;
commit;

--person_position_updated()------------------------------------------------------------------------------------------------------------------------

create or replace function person_position_updated() returns trigger as $$
/*
 * Триггерная функция срабатывает на обновление или добавление записи в person_position
 */
declare last_updated timestamp;
		old_salary numeric;
		old_supervisor_id int;
		old_position_id int;
		position_name text;
		date_begin date;
		date_end date;
		
begin
	-- Блок проверки правильности передаваемых аргументов
	---Проверка, что новая зарплата >0
    IF NEW.salary < 0 then
    	position_name = (select from position where position_id =NEW.position_id);
        RAISE EXCEPTION 'На должности % не может быть отрицательная зарплата', position_name;
    END IF;
    ---- Проверка, что позиция есть в списке позиций
   if check_position_id(new.position_id)='no' then
   		RAISE exception 'Позиция отсутствует в списке';
   	end if;
   ------Проверка, есть ли супервизор в списке сотрудников. 
   if check_supervisor_id(new.supervisor_id)='no' then
   		RAISE exception 'руководитель отсутствует в списке';
   	end if;
   -----Проверка по  дате начала работы на новой позиции
   if new.effective_from is null
   	---дата не NULL
		then raise exception 'date_begin IS NULL'
				USING HINT = 'Не указана дата вступления в должность';
	end if;

    last_updated = current_timestamp;
   	old_position_id = old.position_id;-- позиция
	old_salary = old.salary;-- зарплата
	old_supervisor_id = old.supervisor_id;-- супервизор
	date_begin = old.effective_from;-- дата начала
	date_end = new.effective_from::date - interval '1 day'; --дата окончания
  
  insert into history_position(person_id, old_position_id, old_supervisor_id, old_salary, date_begin, date_end, last_update) 
												values(new.person_id, old_position_id, old_supervisor_id, old_salary, date_begin,date_end, last_updated);

return null;
end;
$$LANGUAGE plpgsql;	

--тесты-------------------------------------------------------------------------------------------------------
--1. Прежняя должность, новая зарплата, новый руководитель. Записи в истории еще не было
begin;
savepoint mysavepoint1;
select * from actual_person where "Фамилия и имя сотрудника" = 'John Obrien';
select * from history_person where "Фамилия и имя сотрудника" = 'John Obrien';
update person_position 
set position_id= 6,
	supervisor_id = 3,
	salary = 35000.,
	effective_from =  now()
where person_id=4;

savepoint mysavepoint2;	
select * from actual_person where "Фамилия и имя сотрудника" = 'John Obrien';
select * from history_person where "Фамилия и имя сотрудника" = 'John Obrien';
rollback to mysavepoint1;
commit;

--2. Прежняя должность, новая зарплата, новый руководитель. есть записи в истории
begin;
savepoint mysavepoint1;
select * from actual_person where "Фамилия и имя сотрудника" = 'Mary Roberts';
select * from history_person where "Фамилия и имя сотрудника" = 'Mary Roberts';
update person_position 
set position_id= 1,
	supervisor_id = 3,
	salary = 35000.,
	effective_from =  now()
where person_id=1;

savepoint mysavepoint2;							
select * from actual_person where "Фамилия и имя сотрудника" = 'Mary Roberts';
select * from history_person where "Фамилия и имя сотрудника" = 'Mary Roberts';
rollback to mysavepoint1;
commit;
select current_date;
--3. Прием на работу архивного сотрудника. Записи в person и history_person_position есть, в person-position - нет. Новая запись в истории не появляется 
begin;
savepoint mysavepoint1;
select * from actual_person where "Фамилия и имя сотрудника" = 'Linda Smith';
select * from history_person where "Фамилия и имя сотрудника" = 'Linda Smith';
insert into person_position (person_id, position_id, supervisor_id, salary, effective_from) 
values ((select person_id from person where person_name = 'Linda Smith'),1, 3, 45000., current_date);

savepoint mysavepoint2;							
select * from actual_person where "Фамилия и имя сотрудника" = 'Linda Smith';
select * from history_person where "Фамилия и имя сотрудника" = 'Linda Smith';
rollback to mysavepoint1;
commit;
--4. ПРием на работу нового сотрудника, по которому нет записей. записи в историю не заносятся
begin;
savepoint mysavepoint1;
select * from actual_person where "Фамилия и имя сотрудника" = 'Вася Пупкин';
select * from history_person where "Фамилия и имя сотрудника" = 'Вася Пупкин';
select from person where person_name = 'Вася Пупкин';
insert into person(person_name,date_birth, email, address)
values('Вася Пупкин','2022-02-02'::date,'vasya@mail.com','деревня Гадюкино');
insert into person_position (person_id, position_id, supervisor_id, salary, effective_from) 
values ((select person_id from person where person_name = 'Вася Пупкин'),1, 3, 1000., current_date);

savepoint mysavepoint2;							
select * from actual_person where "Фамилия и имя сотрудника" = 'Вася Пупкин';
select * from history_person where "Фамилия и имя сотрудника" = 'Вася Пупкин';
rollback to mysavepoint1;
commit;


/*--------------------------------------------------- Триггеры-------------------------------------------------------------------------------------
 person_address_update;
 department_address_update;
 person_position_update;
 */
--person_address_update-срабатывает тогда, когда в таблицe person начинается обновление person_address.--------------------------------------------
create trigger person_address_update 
after update of address on person
for each row
execute procedure person_address_updated();

--department_address_update--срабатывает тогда, когда в таблицe department начинается обновление department_address---------------------------------
create trigger department_address_update
after update of department_address  on department
for each row
execute procedure department_address_updated();

--person_position_update--срабатывает при обновлении  записи о сотруднике в таблицу person_position---------------------------------------------------
create trigger person_position_update
after insert or update  ON  person_position
for each row 
execute procedure person_position_updated();






