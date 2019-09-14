/*
-- Reset?
DROP SCHEMA IF EXISTS sys_meta CASCADE;
CREATE SCHEMA sys_meta;
*/

-- Ban public:
REVOKE ALL ON SCHEMA sys_meta FROM public;

-- Hasse Vertices:
CREATE TYPE sys_meta.group AS ENUM(
    'superuser'                                               -- SUPERUSER CREATE DROP
   ,'chief', 'administrator', 'manager'                       -- GRANT DELETE
   ,'auditor','validator', 'supervisor'                       -- GRANT INSERT/UPDATE
   ,'revisor', 'operator', 'administrative', 'scientific'     -- GRANT SELECT
   ,'technician', 'student'
   ,'www'
   ,'anybody'                                                 -- GRANT CONNECT
   ,'nobody'                                                  -- REVOKE CONNECT
 );

-- Useful domains:
CREATE DOMAIN sys_meta.zorder            AS INTEGER  CHECK(VALUE >= -20 AND VALUE <= 20);
CREATE DOMAIN sys_meta.restrictedrole    AS NAME     CHECK(NOT(VALUE = ANY(enum_range(NULL::sys_meta.group)::NAME[])));
CREATE DOMAIN sys_meta.connectionlimit   AS INTEGER  CHECK(VALUE >= -1 AND VALUE <= 50);
CREATE DOMAIN sys_meta.md5hash           AS TEXT     CHECK(VALUE ~ '^md5[\da-f]{32}');

-- Group (Hasse vertices):
CREATE TABLE sys_meta.groups(
    RoleName     sys_meta.group          NOT NULL
   ,RoleGroups   sys_meta.group[]
   ,Minimal      BOOLEAN                     NOT NULL    DEFAULT(FALSE)       
   ,Maximal      BOOLEAN                     NOT NULL    DEFAULT(FALSE)
   ,Comment      TEXT
    ---
   ,PRIMARY KEY(RoleName)
   ,CHECK(((RoleName = 'nobody') AND (RoleGroups IS NULL) AND Minimal) OR (RoleName != 'nobody'))    -- Nobody is minimal, it has no parents
);
-- Enforce Minimal and Maximal vertices:
CREATE UNIQUE INDEX ON sys_meta.groups(Minimal) WHERE Minimal;
CREATE UNIQUE INDEX ON sys_meta.groups(Maximal) WHERE Maximal;

-- User (extended graph vertices):
CREATE TABLE sys_meta.users(
    RoleName         sys_meta.restrictedrole   NOT NULL
   ,RoleGroups       sys_meta.group[]                    DEFAULT('{nobody}')
   ,Ownership        BOOLEAN                       NOT NULL  DEFAULT(FALSE)
   ,Creable          BOOLEAN                       NOT NULL  DEFAULT(TRUE)
   ,Dropable         BOOLEAN                       NOT NULL  DEFAULT(FALSE)
   ,ConnectionLimit  sys_meta.connectionlimit      NOT NULL  DEFAULT(1)
   ,PasswordHash     sys_meta.md5hash
   ,Comment          TEXT
   ,PRIMARY KEY(RoleName)
    ---
);
-- There can be only one user for system object:
CREATE UNIQUE INDEX ON sys_meta.users(Ownership) WHERE Ownership;
