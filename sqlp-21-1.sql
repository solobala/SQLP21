create database "sqlfree-4"

create role netology with login password 'NetoSQL2019'

drop role netology 

drop owned by netology

revoke all privileges on database "sqlfree-4" from netology

revoke all privileges on database "sqlfree-4" from public

grant connect on database "sqlfree-4" to netology

grant create on database "sqlfree-4" to netology

revoke all privileges on schema public from netology

revoke all privileges on schema public from public

revoke all privileges on schema pg_catalog from netology

revoke all privileges on schema pg_catalog from public

revoke all privileges on schema information_schema from netology

revoke all privileges on schema information_schema from public

grant usage on schema public to netology

grant usage on schema pg_catalog to netology

grant usage on schema information_schema to netology

revoke all on all tables in schema public from netology

revoke all on all tables in schema public from public

revoke all on all tables in schema pg_catalog from netology

revoke all on all tables in schema pg_catalog from public

revoke all on all tables in schema information_schema from netology

revoke all on all tables in schema information_schema from public

grant select on all tables in schema public to netology

grant select on all tables in schema information_schema to netology

grant select on all tables in schema pg_catalog to netology

grant select, insert, update on customer, payment to netology

GRANT ALL ON SCHEMA	some_schema TO some_role;

GRANT SELECT ON ALL TABLES IN SCHEMA some_schema TO some_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA some_schema GRANT SELECT ON TABLES TO some_role;

select *
from pg_catalog.pg_stat_activity
where state = 'active'

select * from flights f

select pg_stat_get_backend_idset ()

select pg_terminate_backend(6480)
