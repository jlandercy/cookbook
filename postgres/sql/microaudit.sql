-- Create Audit Schema:
DROP SCHEMA IF EXISTS sys_audit CASCADE;
CREATE SCHEMA sys_audit;
REVOKE ALL ON SCHEMA sys_audit FROM public;

-- Create DML Enumeration:
DROP TYPE IF EXISTS sys_audit.dml CASCADE;
CREATE TYPE sys_audit.dml AS ENUM('INSERT', 'UPDATE', 'DELETE');

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

-- Bind DDL CREATE TABLE to EVENT TRIGGER:
CREATE EVENT TRIGGER create_table_audit_dml
ON ddl_command_end
WHEN tag IN ('CREATE TABLE')
EXECUTE PROCEDURE sys_audit.bind_audit_dml();
