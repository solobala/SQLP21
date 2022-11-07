--Напишем функцию для получения суммы платежей пользователей между датами

CREATE FUNCTION foo (start_date date, end_date date) returns result_sum numeric

CREATE FUNCTION foo (start_date date, end_date date, OUT result_sum numeric) as $$
--declare x int; y int;
begin
	SELECT SUM(amount)
	FROM payment
	WHERE payment_date::date BETWEEN start_date AND end_date INTO result_sum;
end;
$$ LANGUAGE plpgsql;

select foo('2005-06-15', '2005-06-23')

CREATE or replace FUNCTION foo (start_date date, end_date date, OUT result_sum numeric) as $$
begin
	if start_date is null or end_date is null 
		then raise exception 'Одно из значений отсутствует';
	elsif end_date < start_date
		then raise exception 'Дата окончания меньше даты начала';
	else
		SELECT SUM(amount)
		FROM payment
		WHERE payment_date::date BETWEEN start_date AND end_date INTO result_sum;
	end if;
end;
$$ LANGUAGE plpgsql;

raise notice 
raise warning

select foo('2005-06-15', null)

ОШИБКА: Одно из значений отсутствует

select foo('2005-06-23', '2005-06-15')

ОШИБКА: Дата окончания меньше даты начала

CREATE or replace FUNCTION foo (start_date date, end_date date, cust_id int, OUT result_sum numeric) as $$
begin
	if start_date is null or end_date is null 
		then raise exception 'Одно из значений отсутствует';
	elsif end_date < start_date
		then raise exception 'Дата окончания меньше даты начала';
	else
		SELECT SUM(amount)
		FROM payment
		WHERE payment_date::date BETWEEN start_date AND end_date and customer_id = cust_id INTO result_sum;
	end if;
end;
$$ LANGUAGE plpgsql;

select foo('2005-06-15', '2005-06-23', 3)

drop function foo(date, date)

drop function foo

--Напишем функцию, которая проверяет есть ли у нас такая категория

CREATE FUNCTION foo (cat text) RETURNS text AS $$ 
	BEGIN
		CASE 
			WHEN cat IN (SELECT name FROM category)
			THEN RETURN 'yes';
			ELSE RETURN 'no';
		END CASE;
	END;
$$ LANGUAGE plpgsql

select foo1 ('Comedy')

select foo1 ('Drammma')

create FUNCTION foo1 (cat text) RETURNS text AS $$ 
	BEGIN
		CASE cat
			WHEN 'Comedy' THEN RETURN 'yes';
			WHEN 'Drama' THEN RETURN 'yes';
			WHEN 'Triller' THEN RETURN 'yes';
			ELSE RETURN 'no';
		END CASE;
	END;
$$ LANGUAGE plpgsql

--Усложним конструкцию и напишем функцию, в которую будем передавать сумму платежа, 
--а получать будем таблицу с ФИО пользователя, его общую сумму платежей, которая должна 
--быть больше переданной в функцию и количество аренд.

CREATE FUNCTION foo(in_amount numeric) RETURNS table (user_name text, total_amount numeric, count_rent int) AS $$ 

CREATE FUNCTION foo(in_amount numeric, OUT user_name text, OUT total_amount numeric, 
	OUT count_rent int) RETURNS SETOF record AS $$ 
DECLARE i record;	
begin
	for i in --reverse 1..100
		select customer_id
		from payment 
		group by 1
		having sum(amount) > in_amount
	loop
		select concat(c.last_name, ' ', c.first_name), sum(amount), count(r.inventory_id)
		from payment p 
		join rental r on p.rental_id = r.rental_id
		join customer c on c.customer_id = p.customer_id
		where p.customer_id = i.customer_id
		group by c.customer_id into user_name, total_amount, count_rent;
		return next;
	end loop;
end;
$$ LANGUAGE plpgsql

for (i = 0; i++; i < 100) {  }

select *
from foo((select avg(sum)
	from (
		select customer_id, sum(amount)
		from payment 
		group by 1) t))

create or replace function foo2 () returns table (x int) as $$
begin
	for i in reverse 100..1
	loop 
		select i::int into x;
	return next;
	end loop;
end;
$$ LANGUAGE plpgsql

select * from foo2()

create or replace function foo2 () returns table (x int) as $$
declare i int = 1;
begin
	while i < 100
	loop 
		select i::int into x;
		i = i + 1;
	return next;
	end loop;
end;
$$ LANGUAGE plpgsql

create or replace function foo2 () returns table (x int) as $$
declare i int = 1;
begin
	loop 
		select i::int into x;
		i = i + 1;
		exit when i > 100;
	return next;
	end loop;
end;
$$ LANGUAGE plpgsql

create or replace function foo2 () returns table (x int) as $$
declare i int = 1;
begin
	loop 
		select i::int into x;
		i = i + 1;
		continue when i < 100;
	return next;
	end loop;
end;
$$ LANGUAGE plpgsql

select * from foo2()

create or replace function foo3 (text[]) returns table (x text) as $$
declare i text;
begin
	foreach i in array $1
	loop 
		select i into x;
	return next;
	end loop;
end;
$$ LANGUAGE plpgsql

select * from foo3((select special_features from film where film_id = 102))

--Следующая функция вернет список продаж на указанную дату:

CREATE FUNCTION foo4(date) RETURNS SETOF payment AS $$
BEGIN
    RETURN QUERY 																		
	    	SELECT * FROM payment WHERE payment_date::date = $1;
	IF NOT FOUND THEN
        RAISE EXCEPTION 'На % продаж не было', $1;
    END IF;
    RETURN;
END;
$$ LANGUAGE plpgsql;


select *
from foo4('2005-06-15')

create role test_user with login 

drop role test_user

alter role "test_user" valid until '2022-10-31 00:00:00' (select date_trunc('month', current_date + interval '1 month') - interval '1 day')

select date_trunc('month', current_date + interval '1 month') - interval '1 day'


do $$
	declare x date = (select date_trunc('month', current_date + interval '1 month') - interval '1 day');
		y text = 'test_user';
	begin
		execute 'alter role ' || quote_ident(y) || ' valid until ' || quote_literal(x);
	end;	
$$ LANGUAGE plpgsql;

select * from pg_catalog.pg_roles pr

CREATE TABLE summary_report (
	customer_id int2 NOT NULL,
	customer_fio varchar(150) NOT NULL,
	sum_amount numeric(10,2) NOT NULL,
	count_rents int NOT NULL,
	last_payment timestamp NOT NULL)
	
CREATE OR REPLACE FUNCTION summary_report_foo() RETURNS trigger AS $$
DECLARE cust_fio varchar(150) = (
	SELECT CONCAT(last_name, ' ', first_name) 
	FROM customer 
	WHERE customer_id = NEW.customer_id);
	sum_a numeric(10,2) = (SELECT SUM(amount) FROM payment WHERE customer_id = NEW.customer_id);
	count_r int = (SELECT COUNT(*) FROM rental WHERE customer_id = NEW.customer_id);
	last_p timestamp = NEW.payment_date;	
begin
	IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') AND NEW.customer_id NOT IN (SELECT customer_id FROM summary_report)
    	THEN INSERT INTO summary_report (customer_id, customer_fio, sum_amount, count_rents, last_payment)
    		VALUES (NEW.customer_id, cust_fio, sum_a, count_r, last_p);
		ELSEIF TG_OP = 'DELETE' AND OLD.customer_id NOT IN (SELECT customer_id FROM customer)
				THEN DELETE FROM summary_report WHERE customer_id = OLD.customer_id;
		ELSEIF TG_OP = 'INSERT' OR TG_OP = 'UPDATE'
			THEN UPDATE summary_report 
				SET sum_amount = sum_a, count_rents = count_r, last_payment = last_p 
				WHERE customer_id = NEW.customer_id;
		ELSEIF TG_OP = 'DELETE'
		THEN UPDATE summary_report 
			SET sum_amount = sum_a, count_rents = count_r, last_payment = last_p 
			WHERE customer_id = OLD.customer_id;
		END IF;
		RETURN NULL;
end;
$$ LANGUAGE plpgsql;

CREATE TRIGGER summary_report_trigger 
AFTER INSERT OR UPDATE OR DELETE ON payment 
FOR EACH ROW EXECUTE PROCEDURE summary_report_foo();

Begin select foo1('Comedy') commit

CREATE TABLE table_a (
	id serial PRIMARY KEY,
	val int NOT NULL);

INSERT INTO table_a (val)
VALUES (11), (12), (13);

CREATE TABLE table_b (
	id serial PRIMARY KEY,
	val int NOT NULL,
	created_at timestamp DEFAULT now());

CREATE FUNCTION f1() RETURNS void AS $$
	BEGIN
		FOR i IN 1..10
		LOOP 
			IF i%2 = 0 
				THEN 
					INSERT INTO table_b(val)
					VALUES (i);
			END IF;
		END LOOP;
	END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION f2() RETURNS void AS $$
	DECLARE i record;
	BEGIN
		PERFORM f1();
		FOR i IN 
			SELECT val FROM table_a
		LOOP 
			INSERT INTO table_b(val)
			VALUES (i.val);
		END LOOP;
	END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION f3() RETURNS void AS $$
	BEGIN
		PERFORM f2();
	END;
$$ LANGUAGE plpgsql;

SELECT f3();

select * from table_b

delete from table_b

CREATE PROCEDURE p1() AS $$
	BEGIN
		FOR i IN 1..10
		LOOP 
			INSERT INTO table_b(val)
			VALUES (i);
			IF i%2 = 0 
				THEN COMMIT; 
			ELSE 
				ROLLBACK;
			END IF;
		END LOOP;
	END;
$$ LANGUAGE plpgsql;

CREATE PROCEDURE p2() AS $$
	DECLARE i record;
	BEGIN
		CALL p1();
		FOR i IN 
			SELECT val FROM table_a
		LOOP 
			INSERT INTO table_b(val)
			VALUES (i.val);
		END LOOP;
	END;
$$ LANGUAGE plpgsql;

CREATE PROCEDURE p3() AS $$
	BEGIN
		CALL p2();
	END;
$$ LANGUAGE plpgsql;

call p3()

select * from table_b

do $$
	begin
		commit
		rollback
	end;	
$$ LANGUAGE plpgsql;

Задание 1. Напишите функцию, которая принимает на вход название должности (например, стажер), 
а также даты периода поиска, и возвращает количество вакансий, опубликованных по этой должности в заданный период.

Задание 2. Напишите триггер, срабатывающий тогда, когда в таблицу position добавляется значение grade, 
которого нет в таблице-справочнике grade_salary. Триггер должен возвращать предупреждение пользователю 
о несуществующем значении grade.

Задание 4. Напишите процедуру, которая содержит в себе транзакцию на вставку данных в таблицу employee_salary. 
Входными параметрами являются поля таблицы employee_salary.

Задание 3. Создайте таблицу employee_salary_history с полями:
emp_id - id сотрудника
salary_old - последнее значение salary (если не найдено, то 0)
salary_new - новое значение salary
difference - разница между новым и старым значением salary
last_update - текущая дата и время
Напишите триггерную функцию, которая срабатывает при добавлении новой записи о сотруднике или при 
обновлении значения salary в таблице employee_salary, и заполняет таблицу employee_salary_history данными.

- самая первая запись по сотруднику
- очередная запись по сотруднику
- обновление существующей записи