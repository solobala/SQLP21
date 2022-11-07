/*************************************************************************************************
������ 2. �������� ������� �� ���� "�������� ���������"
************************************************************************************************
������� 1.�������� �������, ������� ��������� �� ���� �������� ��������� (��������, ������), 
� ����� ���� ������� ������, � ���������� ���������� ��������, 
�������������� �� ���� ��������� � �������� ������ 
************************************************************************************************/
set search_path to hr;
--------------------------------------------------------------------------------------------------------------------
CREATE or replace FUNCTION check_positions (category text) RETURNS text as $$
/* ��������������� �������
 * ���������, ��������� �� ������������� ��������� � ������ ���������� 
 * ������ ����������� �� ���������� �������� vac_title ������� vacancy
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
/* ��������������� �������
 * ���������, ������������� �� ������������� ��������� �������
 * ������ - ����� ���������� , ��������, ������
 */
begin
	if $1 ~ '[a-zA-Z�-��-� ]'
		then return 'yes';
	else 
		return 'no';
	end if;
end;
$$LANGUAGE plpgsql;

--------------------------------------------------------------------------------------------------------------------
create or replace function get_vacation_amount(in position_name text, in start_date DATE, in end_date DATE, out quantity integer) as $$
/*
 * ������� ��������� �� ���� �������� ��������� (��������, ������), 
 * � ����� ���� ������� ������, � ���������� ���������� ��������, 
 * �������������� �� ���� ��������� � �������� ������. 
*/

begin
	if start_date is null 
		then raise exception 'start_date IS NULL'
				USING HINT = '���� ������ �����������';
			
	elseif end_date is null 
		then raise exception 'end_date IS NULL'
				using HINT = '���� ��������� �����������';
			
	elseif end_date < start_date
		then raise exception 'end_date < start_date'
				using HINT = '���� ��������� < ���� ������';
			
	elseif position_name is null 
		then raise exception 'position_name is null '
				using HINT = '�� ������� �������� ���������';
			
	elseif is_string(position_name) = 'no'
		then raise exception  'non-alfabet symbols in position_name'
				using HINT = '������� ������������ ������� - ����������� �������� � ��������';
			
	elseif is_string(position_name) = 'yes' and check_positions(position_name)='no' 
		then raise exception 'position_name not in position table' 
				using HINT = '������������� ��������� ����������� � ������';
	end if;


select COUNT(*) from vacancy v where v.vac_title = position_name and v.create_date::date between start_date and end_date into quantity;
end;
$$language plpgsql;
--------------------------------------------------------------------------------------------------------------------

--�������� �������
--------------------------------------------------------------------------------------------------
-- 1.start_date is NULL - ��������� '���� ������ �����������'
--------------------------------------------------------------------------------------------------
select * from get_vacation_amount('������', NULL, '2020-04-04'); 

--------------------------------------------------------------------------------------------------
-- 2. end_date is NULL - ��������� '���� ��������� �����������'
--------------------------------------------------------------------------------------------------
select * from get_vacation_amount('������','2015-01-01',NULL);

--------------------------------------------------------------------------------------------------
-- 3. end_date < start_date - ��������� '���� ��������� < ���� ������'
--------------------------------------------------------------------------------------------------
select * from get_vacation_amount('������','2020-01-01', '2015-04-04');

--------------------------------------------------------------------------------------------------
-- 4. position_name is null  - ��������� '�� ������� �������� ���������'
--------------------------------------------------------------------------------------------------
select * from get_vacation_amount(NULL,'2015-01-01', '2020-04-04');

--------------------------------------------------------------------------------------------------
-- 5. position_name !~ '[a-zA-Z�-��-�]' - ��������� '������� ������������ ������� - ����������� �������� � ��������'

--------------------------------------------------------------------------------------------------
 select * from get_vacation_amount('#%^123834','2015-01-01', '2020-04-04');

--------------------------------------------------------------------------------------------------
-- 6. check_positions(position_name)='no'  - ��������� '������������� ��������� ����������� � ������'
--------------------------------------------------------------------------------------------------
select * from get_vacation_amount('���������','2015-01-01', '2020-04-04');

--------------------------------------------------------------------------------------------------
-- 7. ���������� �������� ������
--------------------------------------------------------------------------------------------------
select * from get_vacation_amount('������','2015-01-01', '2020-04-04');
--------------------------------------------------------------------------------------------------

/************************************************************************************************
������� 2. �������� �������, ������������� �����, ����� � ������� position ����������� 
�������� grade, �������� ��� � �������-����������� grade_salary. 
������� ������ ���������� �������������� ������������ � �������������� �������� grade.
************************************************************************************************/
-- drop function check_grade(int);
create or replace function check_grade (int4) RETURNS boolean as $$
/* ��������������� ������� ���������, ��������� �� 
 * ������������� grade � �������-����������� grade_salary.*/
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
/* ���������� �������, ������������ �������������� ������������ � �������������� �������� grade,
 * ����� � ������� position ����������� �������� grade, �������� ��� � �������-����������� grade_salary.*/
begin 
	if check_grade(new.grade)= FALSE
		then raise exception '�������� grade �����������  � �������!';
	end if;
	RETURN NEW;
end;
$$LANGUAGE plpgsql;
--------------------------------------------------------------------------------------------------------------------
--drop trigger position_added on position;
create trigger position_added
/*
 * ������� ����������� �����, ����� � ������� position ����������� �������� grade, 
�������� ��� � �������-����������� grade_salary. 
�������  ���������� �������������� ������������ � �������������� �������� grade.
 */
before insert on position
for each row
execute procedure position_added();
-------------------------------------------------------------------------------------------------
--�������� �������
--------------------------------------------------------------------------------------------------
--1. ���������� �������� grade - ������ ����������� ������ � ������� position
--------------------------------------------------------------------------------------------------
begin;
savepoint mysavepoint1;
insert into position(pos_id, pos_title, pos_category, unit_id, grade,address_id, manager_pos_id) 
values(
(select pos_id from position order by 1 desc limit 1)+1, 
'����������', '����������������', 214, 5, 10, 2); 
select * from position where pos_id = (select pos_id from position order by 1 desc limit 1);
rollback to mysavepoint1;
commit;
--------------------------------------------------------------------------------------------------
--2. ������������ �������� grade - ����� � ��������������� �� ������������� ��������
--------------------------------------------------------------------------------------------------
begin;
savepoint mysavepoint2;	
insert into position(pos_id,pos_title, pos_category, unit_id, grade,address_id, manager_pos_id) 
values(
(select pos_id from position order by 1 desc limit 1)+1,  
'����������', '����������������', 214, 10, 10, 2); 
rollback to mysavepoint2;
commit;

/************************************************************************************************
������� 3. �������� ������� employee_salary_history � ������:

emp_id - id ����������
salary_old - ��������� �������� salary (���� �� �������, �� 0)
salary_new - ����� �������� salary
difference - ������� ����� ����� � ������ ��������� salary
last_update - ������� ���� � �����

�������� ���������� �������, ������� ����������� ��� ���������� ����� ������ � ���������� 
��� ��� ���������� �������� salary � ������� employee_salary, 
� ��������� ������� employee_salary_history �������.
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
 ��������������� �-�, ����������� ������� ������� � �������� ���������� 
 � ������e employee_salary_history
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
 ��������������� �-�, ����������� ������� ������� � �������� ���������� 
 � ������e employee_salary_history
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
 ��������������� �-� ��������� order_id ��������� ������ � ��������
 ������� employee_salary
 */
begin
	select order_id from employee_salary  order by 1 desc limit 1 into order_id_;
end;
$$LANGUAGE plpgsql;
 
--------------------------------------------------------------------------------------------------------------------

create or replace function employee_salary_added() returns trigger as $$
/*
 * ���������� �������, ������� ����������� ��� ���������� ����� ������ � ���������� 
��� ��� ���������� �������� salary � ������� employee_salary, 
� ��������� ������� employee_salary_history �������.
 */
declare last_updated timestamp;
		old_salary numeric;
		
begin
	-- ���� �������� ������������ ������������ ����������

    IF NEW.salary < 0 THEN
        RAISE EXCEPTION '� % �� ����� ���� ������������� ��������', NEW.emp_id;
    END IF;
    
   last_updated = current_timestamp;
	
   -- ������� �������� �� ������� INSERT
  		-- ����� ������ ������ �� ����������
  
    IF (TG_OP = 'INSERT') AND (check_emp_id(new.emp_id) = 'no') then 
		begin
	    	old_salary = get_old_salary(new.emp_id) ;

			insert into employee_salary_history(emp_id, salary_old, salary_new, last_update) 
												values(new.emp_id, old_salary, new.salary, last_updated);
		end;
	elseif (TG_OP = 'INSERT') AND (check_emp_id(new.emp_id) = 'yes') then-- ��������� ������ �� ����������
		begin
			old_salary = get_old_salary(new.emp_id);

			insert into employee_salary_history(emp_id, salary_old, salary_new, last_update) 
												values(new.emp_id, old_salary, new.salary, last_updated);
		end;
	-- ������� �������� �� ������� UPDATE
										
	
    elseif (TG_OP = 'UPDATE') AND  (check_emp_id(new.emp_id)='yes') then --������ update ��������� ������ �� ����������
    	
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

/* ������� ����������� ��� ���������� ����� ������ � ���������� 
��� ��� ���������� �������� salary � ������� employee_salary*/

AFTER INSERT OR update of salary ON employee_salary
for each row execute procedure employee_salary_added();

/************************************************************************************************
 �������� �������
 �������� �������� ������ � �������� person(person_id=) � employee(emp_id=2736)
*/
begin;
savepoint mysavepoint1;--������ � ��������
delete from employee_salary where emp_id = 2736;
delete from employee where emp_id = 2736;
delete from person where person_id = 4591;
select * from person where person_id = 4591;
select * from employee_salary where emp_id = 2736;
select * from employee_salary_history where emp_id  = 2736;

savepoint mysavepoint2;
insert into person(person_id, first_name, middle_name, last_name,taxpayer_number, dob) values(4591,'����', '��������', '������','772708176262', Null);
insert into employee(emp_id, emp_type_id, person_id,pos_id, rate,hire_date) values(2736, 1, 4591, 5, 1.,'2022-10-01');
select * from person where person_id = 4591;
select * from employee where emp_id = 2736;
select * from employee_salary where emp_id  = 2736;
select * from employee_salary_history where emp_id  = 2736;
savepoint  mysavepoint3;
commit;
--------------------------------------------------------------------------------------------------
--1. NEW.salary < 0 - �������������� '� % �� ����� ���� ������������� ��������'
--------------------------------------------------------------------------------------------------

insert into employee_salary(order_id, emp_id, salary, effective_from) values (
(select order_id from employee_salary order by 1 desc limit 1)+1,
2736, -20000., '2022-10-01');

--------------------------------------------------------------------------------------------------
--2. ���������� ����� ������ ������ �� ����������, ��� emp_id ���� � ������� employee, � ������� employee_salary.
--   ������ ���������� ������ � ������� employee_salary_history, �������� salary_old ��������������� = 0
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
--3. ���������� ��������� ������ �� ����������, ��� emp_id ���� � ������� employee, � ������� employee_salary.
--   ������ ���������� ������ � ������� employee_salary_history, �������� salary_old ��������������� = OLD.salary, �������� salary_new =NEW.salary
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
--8. ���������� ��������� ������ �� salary ����������, 
--    ��� emp_id ���� � ������� employee � � ������� employee_salary.
--   ������ ��������� ���������� salary, � �����  ���������� ������ � ������� employee_salary_history;
--  �������� salary_old ��������������� = OLD.salary, �������� salary_new =NEW.salary
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
 * ������� 4. 
 * �������� ���������, ������� �������� � ���� ���������� �� ������� ������ � ������� employee_salary. 
 * �������� ����������� �������� ���� ������� employee_salary.
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
