-- https://www.postgresql.org/docs/current/static/ddl-rowsecurity.html

-- Become Super User:
SET ROLE scidata;

DROP TABLE IF EXISTS userdata CASCADE;
CREATE TABLE userdata(
    Id          SERIAL     NOT NULL
   ,Ownership   NAME       NOT NULL  DEFAULT(current_user)
   ,UserKey     TEXT       NOT NULL
   ,PRIMARY KEY(Id)
   ,UNIQUE(UserKey)
);

-- Associate privileges to group roles (bottom-up approach):
GRANT CONNECT ON DATABASE airdata TO anybody;

GRANT USAGE ON SCHEMA public TO scientific;
GRANT SELECT ON TABLE userdata TO scientific;

GRANT INSERT, UPDATE ON TABLE userdata TO manager;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO manager;

GRANT ALL ON TABLE userdata TO chief;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO chief;

-- Enable Row Level Security
ALTER TABLE userdata ENABLE ROW LEVEL SECURITY;

-- Create a Policy (user oriented filter)
CREATE POLICY userdata_rls_roles ON userdata USING(pg_has_role(Ownership, 'usage'));

-- Become Chief:
SET ROLE jean;
-- Add private data (by default rows belong to user who created them):
INSERT INTO userdata(UserKey) VALUES ('CO/B001'), ('SO2/B001');
-- Share data with Chiefs (generalization):
INSERT INTO userdata(Ownership, UserKey) VALUES ('chief', 'x0/B001'), ('chief', 'x1/B001');
-- Share data with Managers (generalization and downgrade):
INSERT INTO userdata(Ownership, UserKey) VALUES ('manager', 'NO/B001'), ('manager', 'NO2/B001');
-- Share data with a specific manager
/*
INSERT INTO userdata(Ownership, UserKey) VALUES ('celine', 'NO/B003'), ('celine', 'NO2/B003');
ERROR: new row violates row-level security policy for table "userdata"
État SQL :42501
*/

-- Check transitivity (both user are not comparable together):
SET ROLE jean;
SELECT pg_has_role('celine', 'usage');

-- Become Manager:
SET ROLE celine;
-- Add private data:
INSERT INTO userdata(UserKey) VALUES ('CO2/B001'), ('NOx/B001');
-- Add shared data (generalization):
INSERT INTO userdata(Ownership, UserKey) VALUES ('manager', 'NO/B002'), ('manager', 'NO2/B002');
-- Add public data (generalization and downgrade)
INSERT INTO userdata(Ownership, UserKey) VALUES ('anybody', 'NO/B004'), ('anybody', 'NO2/B004');


SET ROLE manuel;
/*
INSERT INTO userdata(UserKey) VALUES ('T/B001'), ('v/B001');
ERROR: permission denied for relation userdata
État SQL :42501
*/
SELECT * FROM userdata;

-- Super User see all data:
SET ROLE scidata;
SELECT * FROM userdata;

SET ROLE jean;
SELECT * FROM userdata;

SET ROLE celine;
SELECT * FROM userdata;

SET ROLE manuel;
SELECT * FROM userdata;
