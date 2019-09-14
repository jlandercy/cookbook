# Micro DML Audit

Triggers and Event triggers perform additional operations when respectively executing DML and DDL statements. Triggers are useful, specialy for auditing database usage.

We develop in this article an example of `TRIGGER` and `EVENT TRIGGER` for auditing purposes. Complete executable SQL code is available [here](/sql/audit/microaudit.sql).

## Audit Structure

First we create a schema where the audit mechanism will be stored:

```sql
-- Create Audit Schema:
DROP SCHEMA IF EXISTS sys_audit CASCADE;
CREATE SCHEMA sys_audit;
REVOKE ALL ON SCHEMA sys_audit FROM public;
```

For convenience we create a enumeration:

```sql
-- Create DML Enumeration:
DROP TYPE IF EXISTS sys_audit.dml CASCADE;
CREATE TYPE sys_audit.dml AS ENUM('INSERT', 'UPDATE', 'DELETE');
```

Then we create a table that will host audit informations:

```sql
-- Create Audit Table:
DROP TABLE IF EXISTS sys_audit.audit_dml CASCADE;
CREATE TABLE sys_audit.audit_dml(
    Id           BIGSERIAL        NOT NULL
   ,TimeValue    TIMESTAMP        NOT NULL
   ,RoleName     NAME             NOT NULL
   ,ClientIP     INET             NOT NULL
   ,BackEndPid   INTEGER          NOT NULL
   ,Operation    sys_audit.dml    NOT NULL
   ,Relation     regclass         NOT NULL
   ,NewRecord    JSONB
   ,OldRecord    JSONB
    ---
   ,PRIMARY KEY(Id)
);
```

Now everything is ready for starting the audit. We just miss some trigger mechanism feeding the audit table. Lets start the magic.

## Audit DML Trigger

First we define a Trigger Function that feed the audit table when DML (`INSERT`, `UPDATE`, `DELETE`) statements are issued.
This function will act at the `ROW` level, thererfore it must return record (`NEW` or `OLD`).

```sql
-- Create Audit Trigger Function:
DROP FUNCTION IF EXISTS sys_audit.audit_dml() CASCADE;
CREATE OR REPLACE FUNCTION sys_audit.audit_dml()
RETURNS TRIGGER AS
$BODY$
DECLARE

History  BOOLEAN := (TG_NARGS > 0) AND (TG_ARGV[0]::BOOLEAN);
Relation regclass := (TG_TABLE_SCHEMA || '.' || TG_RELNAME);
NewRecord JSONB;
OldRecord JSONB;

BEGIN 

IF TG_OP = ANY('{INSERT,UPDATE}') THEN
    IF History THEN
        NewRecord := to_jsonb(NEW);
    END IF;
END IF;

IF TG_OP = ANY('{UPDATE,DELETE}') THEN
    IF History THEN
        OldRecord := to_jsonb(OLD);
    END IF;
END IF;

INSERT INTO sys_audit.audit_dml(TimeValue, RoleName, ClientIP, BackEndPID, Operation, Relation, NewRecord, OldRecord) VALUES
(now()::TIMESTAMP, current_user, inet_client_addr(), pg_backend_pid(), TG_OP::sys_audit.dml, Relation, NewRecord, OldRecord);

IF TG_OP = ANY('{INSERT,UPDATE}') THEN
    RETURN NEW;
ELSIF TG_OP = 'DELETE' THEN
    RETURN OLD;
ELSE
    RAISE EXCEPTION 'Cannot fire Audit DML Trigger on: %', TG_OP;
END IF; 

END;
$BODY$
LANGUAGE plpgsql SECURITY DEFINER;
```

If we want a table to be audited, we just need to bind this function using a trigger and fire it on specific DML statements. This can be achieved by issuing:

```sql
CREATE TRIGGER "trigger_name" BEFORE INSERT OR UPDATE OR DELETE ON "table_name"
FOR EACH ROW EXECUTE PROCEDURE sys_audit.audit_dml(TRUE);'
```

Note that the extra parameter passed to the function controls the `JSON` storage of old and new records into the audit table. Set it up to false, if the table to be audited contains heavy columns or will have a huge amount of rows touched.

## Audit DDL Trigger

The above solution works fine, but does not scale well when you have to audit serveral tables. PostgreSQL (this is not Standard SQL) defines `EVENT TRIGGERS` that fires when DDL (`CREATE` or `DROP`) statements are issued. This kind of triggers makes administrator life easier because it spares you a lot of code to write and avoids table auditing omission.

Informations about the current DDL statement executed can be fetched by `pg_event_trigger_ddl_commands()` (only available in the scope of event trigger functions). Records returned by this function must be filtered out because multiple objects can be created when issuing a DDL statement. In our case, we want only add a trigger to a table, but index can also be created meanwhile the table is created if primary key or constraints are defined within the table.

> pg_event_trigger_ddl_commands returns a list of DDL commands executed by each user action, when invoked in a function attached to a ddl_command_end event trigger. If called in any other context, an error is raised. 

```sql
-- Create Event Trigger (on DDL: CREATE TABLE)
DROP FUNCTION IF EXISTS sys_audit.bind_audit_dml() CASCADE;
CREATE OR REPLACE FUNCTION sys_audit.bind_audit_dml()
RETURNS event_trigger AS 
$BODY$
DECLARE

rec RECORD;

BEGIN

FOR Rec IN

SELECT * FROM pg_catalog.pg_event_trigger_ddl_commands()

LOOP

IF rec.object_type = 'table' THEN

EXECUTE format('
CREATE TRIGGER %s_audit_dml BEFORE INSERT OR UPDATE OR DELETE ON %s
FOR EACH ROW EXECUTE PROCEDURE sys_audit.audit_dml(TRUE);'
,REPLACE(rec.object_identity, '.', '_')
,rec.object_identity::regclass
);

END IF;

END LOOP;

END;
$BODY$
LANGUAGE plpgsql;
```

Likewise classic triggers, last step is binding function to a trigger. In order to restrain the output of `pg_event_trigger_ddl_commands()` we add a pre-filter condition on the trigger to limit it to table creation only.

```sql
-- Bind DDL CREATE TABLE to EVENT TRIGGER:
CREATE EVENT TRIGGER create_table_audit_dml
ON ddl_command_end
WHEN tag IN ('CREATE TABLE')
EXECUTE PROCEDURE sys_audit.bind_audit_dml();
```

That is it! At this point, future created tables will be blessed with our `sys_audit.audit_dml()` trigger function and therefore DML audit is enforced without any additional effort.

## Resources
Further detailed informations on concepts developed above can be found in the current PostgreSQL reference.
Reader may be intersted by the following relevant bookmarks:

- [Event Trigger Definition](https://www.postgresql.org/docs/current/static/event-trigger-definition.html);
- [Create Event Trigger](https://www.postgresql.org/docs/current/static/sql-createeventtrigger.html);
- [Event Trigger Fields](https://www.postgresql.org/docs/current/static/functions-event-triggers.html)
- [Create Trigger Function](https://www.postgresql.org/docs/current/static/plpgsql-trigger.html);
- [Create Trigger](https://www.postgresql.org/docs/current/static/sql-createtrigger.html);
