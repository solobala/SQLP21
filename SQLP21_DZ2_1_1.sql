/*************************************************************************************************
Модуль 2. Домашнее задание по теме "Хранимые процедуры"
************************************************************************************************
Задание 1.Напишите функцию, которая принимает на вход название должности (например, стажер), 
а также даты периода поиска, и возвращает количество вакансий, 
опубликованных по этой должности в заданный период 
************************************************************************************************/
set search_path to hr;
--------------------------------------------------------------------------------------------------------------------
CREATE or replace FUNCTION check_positions (category text) RETURNS text as $$
/* Вспомогательная Функция
 * проверяет, находится ли запрашиваемая должность в списке должностей 
 * Список формируется из уникальных значений vac_title таблицы vacancy
 */
begin
	CASE WHEN category IN (SELECT distinct vac_title FROM vacancy)
		THEN RETURN 'yes';
	ELSE 
		RETURN 'no';
	END CASE;
END;
$$LANGUAGE plpgsql;
--------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION is_string(text) RETURNS text AS $$
/* Вспомогательная Функция
 * проверяет, соответствует ли запрашиваемая должность шаблону
 * Шаблон - буквы кирриллицы , латиницы, пробел
 */
begin
	if $1 ~ '[a-zA-Zа-яА-Я ]'
		then return 'yes';
	else 
		return 'no';
	end if;
end;
$$LANGUAGE plpgsql;

--------------------------------------------------------------------------------------------------------------------
create or replace function get_vacation_amount(in position_name text, in start_date DATE, in end_date DATE, out quantity integer) as $$
/*
 * Функция принимает на вход название должности (например, стажер), 
 * а также даты периода поиска, и возвращает количество вакансий, 
 * опубликованных по этой должности в заданный период. 
*/

begin
	if start_date is null 
		then raise exception 'start_date IS NULL'
				USING HINT = 'Дата начала отсутствует';
			
	elseif end_date is null 
		then raise exception 'end_date IS NULL'
				using HINT = 'Дата окончания отсутствует';
			
	elseif end_date < start_date
		then raise exception 'end_date < start_date'
				using HINT = 'Дата окончания < даты начала';
			
	elseif position_name is null 
		then raise exception 'position_name is null '
				using HINT = 'Не указано название должности';
			
	elseif is_string(position_name) = 'no'
		then raise exception  'non-alfabet symbols in position_name'
				using HINT = 'Введены неправильные символы - используйте кирилицу и латиницу';
			
	elseif is_string(position_name) = 'yes' and check_positions(position_name)='no' 
		then raise exception 'position_name not in position table' 
				using HINT = 'Запрашиваемая должность отсутствует в списке';
	end if;


select COUNT(*) from vacancy v where v.vac_title = position_name and v.create_date::date between start_date and end_date into quantity;
end;
$$language plpgsql;
--------------------------------------------------------------------------------------------------------------------

--Тестовые запросы
--------------------------------------------------------------------------------------------------
-- 1.start_date is NULL - сообщение 'Дата начала отсутствует'
--------------------------------------------------------------------------------------------------
select * from get_vacation_amount('стажер', NULL, '2020-04-04'); 

--------------------------------------------------------------------------------------------------
-- 2. end_date is NULL - Сообщение 'Дата окончания отсутствует'
--------------------------------------------------------------------------------------------------
select * from get_vacation_amount('стажер','2015-01-01',NULL);

--------------------------------------------------------------------------------------------------
-- 3. end_date < start_date - Сообщение 'Дата окончания < даты начала'
--------------------------------------------------------------------------------------------------
select * from get_vacation_amount('стажер','2020-01-01', '2015-04-04');

--------------------------------------------------------------------------------------------------
-- 4. position_name is null  - Сообщение 'не указано название должности'
--------------------------------------------------------------------------------------------------
select * from get_vacation_amount(NULL,'2015-01-01', '2020-04-04');

--------------------------------------------------------------------------------------------------
-- 5. position_name !~ '[a-zA-Zа-яА-Я]' - Сообщение 'Введены неправильные символы - используйте кирилицу и латиницу'

--------------------------------------------------------------------------------------------------
 select * from get_vacation_amount('#%^123834','2015-01-01', '2020-04-04');

--------------------------------------------------------------------------------------------------
-- 6. check_positions(position_name)='no'  - Сообщение 'запрашиваемая должность отсутствует в списке'
--------------------------------------------------------------------------------------------------
select * from get_vacation_amount('космонавт','2015-01-01', '2020-04-04');

--------------------------------------------------------------------------------------------------
-- 7. корректные исходные данные
--------------------------------------------------------------------------------------------------
select * from get_vacation_amount('стажер','2015-01-01', '2020-04-04');
--------------------------------------------------------------------------------------------------

/************************************************************************************************
Задание 2. Напишите триггер, срабатывающий тогда, когда в таблицу position добавляется 
значение grade, которого нет в таблице-справочнике grade_salary. 
Триггер должен возвращать предупреждение пользователю о несуществующем значении grade.
************************************************************************************************/
-- drop function check_grade(int);
create or replace function check_grade (int4) RETURNS boolean as $$
/* Вспомогательная функция проверяет, находится ли 
 * запрашиваемая grade в таблице-справочнике grade_salary.*/
begin
	if $1 IN (SELECT  grade FROM grade_salary)
		then return TRUE;
	else 
		return FALSE;
	end if;
end;
$$LANGUAGE plpgsql;
--------------------------------------------------------------------------------------------------------------------
create or replace function position_added() returns trigger as $$
/* Триггерная функция, возвращающая предупреждение пользователю о несуществующем значении grade,
 * когда в таблицу position добавляется значение grade, которого нет в таблице-справочнике grade_salary.*/
begin 
	if check_grade(new.grade)= FALSE
		then raise exception 'Значение grade отсутствует  в таблице!';
	end if;
	RETURN NEW;
end;
$$LANGUAGE plpgsql;
--------------------------------------------------------------------------------------------------------------------
--drop trigger position_added on position;
create trigger position_added
/*
 * триггер срабатывает тогда, когда в таблицу position добавляется значение grade, 
которого нет в таблице-справочнике grade_salary. 
Триггер  возвращает предупреждение пользователю о несуществующем значении grade.
 */
before insert on position
for each row
execute procedure position_added();
-------------------------------------------------------------------------------------------------
--тестовые запросы
--------------------------------------------------------------------------------------------------
--1. Корректное значение grade - должна добавляться запись в таблицу position
--------------------------------------------------------------------------------------------------
begin;
savepoint mysavepoint1;
insert into position(pos_id, pos_title, pos_category, unit_id, grade,address_id, manager_pos_id) 
values(
(select pos_id from position order by 1 desc limit 1)+1, 
'специалист', 'Административный', 214, 5, 10, 2); 
select * from position where pos_id = (select pos_id from position order by 1 desc limit 1);
rollback to mysavepoint1;
commit;
--------------------------------------------------------------------------------------------------
--2. Некорректное значение grade - выход с предупреждением об отсутствующем значении
--------------------------------------------------------------------------------------------------
begin;
savepoint mysavepoint2;	
insert into position(pos_id,pos_title, pos_category, unit_id, grade,address_id, manager_pos_id) 
values(
(select pos_id from position order by 1 desc limit 1)+1,  
'специалист', 'Административный', 214, 10, 10, 2); 
rollback to mysavepoint2;
commit;

/************************************************************************************************
Задание 3. Создайте таблицу employee_salary_history с полями:

emp_id - id сотрудника
salary_old - последнее значение salary (если не найдено, то 0)
salary_new - новое значение salary
difference - разница между новым и старым значением salary
last_update - текущая дата и время

Напишите триггерную функцию, которая срабатывает при добавлении новой записи о сотруднике 
или при обновлении значения salary в таблице employee_salary, 
и заполняет таблицу employee_salary_history данными.
************************************************************************************************/
drop table employee_salary_history;
create table employee_salary_history(emp_id int4 not null, 
									salary_old numeric(12,2) not null default 0, 
 									salary_new numeric(12,2) not null, 
									difference numeric(12,2) generated always as (salary_new-salary_old) stored not null, 
									last_update timestamp not null default now());
--------------------------------------------------------------------------------------------------------------------
create or replace function check_emp_id(int) returns text as $$
/*
 Вспомогательная ф-я, проверяющая наличие записей о зарплате сотрудника 
 в таблицe employee_salary_history
 */
begin  
	if $1  IN (SELECT emp_id FROM employee_salary_history group by 1) then
		RETURN 'yes';
	else 
		return 'no';
	end if;
end;
$$LANGUAGE plpgsql;
--------------------------------------------------------------------------------------------------------------------
create or replace function get_old_salary(int, out old_salary numeric)  as $$
/*
 Вспомогательная ф-я, проверяющая наличие записей о зарплате сотрудника 
 в таблицe employee_salary_history
 */
begin  
	select salary from employee_salary es where emp_id = $1 order by order_id desc limit 1 offset 1 into old_salary;
	if not found then
		old_salary = 0;
	end if;
end;
$$LANGUAGE plpgsql;

--------------------------------------------------------------------------------------------------------------------
--drop function get_new_order_id;
create or replace function get_new_order_id (out order_id_ integer)  as $$
/*
 Вспомогательная ф-я получения order_id последней записи о зарплате
 таблицы employee_salary
 */
begin
	select order_id from employee_salary  order by 1 desc limit 1 into order_id_;
end;
$$LANGUAGE plpgsql;
 
--------------------------------------------------------------------------------------------------------------------

create or replace function employee_salary_added() returns trigger as $$
/*
 * Триггерная функция, которая срабатывает при добавлении новой записи о сотруднике 
или при обновлении значения salary в таблице employee_salary, 
и заполняет таблицу employee_salary_history данными.
 */
declare last_updated timestamp;
		old_salary numeric;
		
begin
	-- Блок проверки правильности передаваемых аргументов

    IF NEW.salary < 0 THEN
        RAISE EXCEPTION 'У % не может быть отрицательная зарплата', NEW.emp_id;
    END IF;
    
   last_updated = current_timestamp;
	
   -- Триггер сработал на событие INSERT
  		-- самая первая запись по сотруднику
  
    IF (TG_OP = 'INSERT') AND (check_emp_id(new.emp_id) = 'no') then 
		begin
	    	old_salary = get_old_salary(new.emp_id) ;

			insert into employee_salary_history(emp_id, salary_old, salary_new, last_update) 
												values(new.emp_id, old_salary, new.salary, last_updated);
		end;
	elseif (TG_OP = 'INSERT') AND (check_emp_id(new.emp_id) = 'yes') then-- очередная запись по сотруднику
		begin
			old_salary = get_old_salary(new.emp_id);

			insert into employee_salary_history(emp_id, salary_old, salary_new, last_update) 
												values(new.emp_id, old_salary, new.salary, last_updated);
		end;
	-- Триггер сработал на событие UPDATE
										
	
    elseif (TG_OP = 'UPDATE') AND  (check_emp_id(new.emp_id)='yes') then --Делаем update последней записи по сотруднику
    	
    	begin

			insert into employee_salary_history(emp_id, salary_old, salary_new, last_update) 
												values(new.emp_id, old.salary, new.salary, last_updated);
   		end;
   
  end if;

  return null;
end;
$$LANGUAGE plpgsql;	


--------------------------------------------------------------------------------------------------------------------
-- drop trigger employee_salary_added on employee_salary;
create trigger employee_salary_added

/* триггер срабатывает при добавлении новой записи о сотруднике 
или при обновлении значения salary в таблице employee_salary*/

AFTER INSERT OR update of salary ON employee_salary
for each row execute procedure employee_salary_added();

/************************************************************************************************
 тестовые запросы
 Создадим тестовые записи в таблицах person(person_id=) и employee(emp_id=2736)
*/
begin;
savepoint mysavepoint1;--Записи в таблицах
delete from employee_salary where emp_id = 2736;
delete from employee where emp_id = 2736;
delete from person where person_id = 4591;
select * from person where person_id = 4591;
select * from employee_salary where emp_id = 2736;
select * from employee_salary_history where emp_id  = 2736;

savepoint mysavepoint2;
insert into person(person_id, first_name, middle_name, last_name,taxpayer_number, dob) values(4591,'Иван', 'Иванович', 'Иванов','772708176262', Null);
insert into employee(emp_id, emp_type_id, person_id,pos_id, rate,hire_date) values(2736, 1, 4591, 5, 1.,'2022-10-01');
select * from person where person_id = 4591;
select * from employee where emp_id = 2736;
select * from employee_salary where emp_id  = 2736;
select * from employee_salary_history where emp_id  = 2736;
savepoint  mysavepoint3;
commit;
--------------------------------------------------------------------------------------------------
--1. NEW.salary < 0 - предупреждение 'У % не может быть отрицательная зарплата'
--------------------------------------------------------------------------------------------------

insert into employee_salary(order_id, emp_id, salary, effective_from) values (
(select order_id from employee_salary order by 1 desc limit 1)+1,
2736, -20000., '2022-10-01');

--------------------------------------------------------------------------------------------------
--2. Добавление самой первой записи по сотруднику, чей emp_id есть в таблице employee, в таблицу employee_salary.
--   Должна добавиться запись в таблицу employee_salary_history, значение salary_old устанавливается = 0
--------------------------------------------------------------------------------------------------
begin;
savepoint mysavepoint3;
select * from employee where emp_id = 2736;
select * from employee_salary where emp_id = 2736;
insert into employee_salary(order_id, emp_id, salary, effective_from) values (
get_new_order_id()+1, 2736, 20000., '2022-10-01');
select * from employee_salary where emp_id = 2736;
select * from employee_salary_history where emp_id  = 2736;
savepoint mysavepoint4;
-- rollback to mysavepoint3;
commit;
--------------------------------------------------------------------------------------------------
--3. Добавление очередной записи по сотруднику, чей emp_id есть в таблице employee, в таблицу employee_salary.
--   Должна добавиться запись в таблицу employee_salary_history, значение salary_old устанавливается = OLD.salary, значение salary_new =NEW.salary
--------------------------------------------------------------------------------------------------
begin;
savepoint mysavepoint3;
select * from employee_salary where emp_id = 2736;
select * from employee_salary_history where emp_id  = 2736;
insert into employee_salary(order_id, emp_id, salary, effective_from) values (
get_new_order_id()+1, 2736, 50000., '2022-10-05');
select * from employee_salary where emp_id = 2736;
select * from employee_salary_history where emp_id  = 2736;
-- rollback to mysavepoint3;
commit;
--------------------------------------------------------------------------------------------------
--8. Обновление последней записи по salary сотрудника, 
--    чей emp_id есть в таблице employee и в таблице employee_salary.
--   Должно произойти обновление salary, а также  добавиться запись в таблицу employee_salary_history;
--  значение salary_old устанавливается = OLD.salary, значение salary_new =NEW.salary
--------------------------------------------------------------------------------------------------
begin;
savepoint mysavepoint3;
select * from employee_salary where emp_id = 2736;
select * from employee_salary_history where emp_id  = 2736;
update employee_salary
set salary = 54000.
where emp_id=2736 and effective_from = (select effective_from from employee_salary  where emp_id = 2736 order by 1 desc limit 1);
select * from employee_salary where emp_id = 2736;
select * from employee_salary_history where emp_id  = 2736; 
--rollback to mysavepoint3;
commit;

/*************************************************************************************************
 * Задание 4. 
 * Напишите процедуру, которая содержит в себе транзакцию на вставку данных в таблицу employee_salary. 
 * Входными параметрами являются поля таблицы employee_salary.
 **************************************************************************************************/
--drop procedure p2;
create or REPLACE procedure p2(inout order_id_ int, inout emp_id_ int, inout salary_ numeric, inout effective_from_ timestamp) as $$
	BEGIN
			INSERT INTO employee_salary(order_id, emp_id, salary, effective_from)
			VALUES (order_id_, emp_id_, salary_, effective_from_) ;
	END;
$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
do $$
declare order_id_ int :=get_new_order_id() +1;
	emp_id_ int := 2736;
	salary_ numeric :=61000.; 
	effective_from_ timestamp := current_timestamp;
begin
	call p2(order_id_, emp_id_, salary_,effective_from_);
end;
$$ LANGUAGE plpgsql;

select * from employee_salary;
