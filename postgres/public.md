# PostgreSQL Public Role

https://www.postgresql.org/docs/current/static/sql-grant.html

> The key word `PUBLIC` indicates that the privileges are to be granted to all roles, including those that might be created later. `PUBLIC` can be thought of as an implicitly defined group that always includes all roles. Any particular role will have the sum of privileges granted directly to it, privileges granted to any role it is presently a member of, and privileges granted to `PUBLIC`.

> If `WITH GRANT OPTION` is specified, the recipient of the privilege can in turn grant it to others. Without a grant option, the recipient cannot do that. Grant options cannot be granted to `PUBLIC`.

> PostgreSQL grants default privileges on some types of objects to `PUBLIC`. No privileges are granted to `PUBLIC` by default on tables, columns, schemas or tablespaces. For other types, the default privileges granted to `PUBLIC` are as follows: `CONNECT` and `CREATE TEMP TABLE` for databases; `EXECUTE` privilege for functions; and `USAGE` privilege for languages. The object owner can, of course, `REVOKE` both default and expressly granted privileges. (For maximum security, issue the `REVOKE` in the same transaction that creates the object; then there is no window in which another user can use the object.) Also, these initial default privilege settings can be changed using the `ALTER DEFAULT PRIVILEGES` command.


## PgAdmin III

https://dba.stackexchange.com/a/19154/82457
> If a user's access is limited to one database in pg_hba.conf (which is the most efficient place to do that), you can make it work with pgAdmin by configuring this one database as maintenance db. Nothing bad will come of it.

https://www.pgadmin.org/docs/pgadmin3/1.22/connect.html
> The maintenance DB field is used to specify the initial database that pgAdmin connects to, and that will be expected to have the pgAgent schema and adminpack objects installed (both optional). On PostgreSQL 8.1 and above, the maintenance DB is normally called ‘postgres’, and on earlier versions ‘template1’ is often used, though it is preferrable to create a ‘postgres’ database for this purpose to avoid cluttering the template database.
