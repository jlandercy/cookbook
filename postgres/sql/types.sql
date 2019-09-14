
DROP TYPE IF EXISTS userid CASCADE;

CREATE TYPE userid AS (
    UserKey      TEXT
   ,UserLabel    TEXT
   ,Active       BOOLEAN
   ,Tags         TEXT[]
);

CREATE TABLE tpl_userid OF userid;


ALTER TABLE tpl_userid ALTER COLUMN UserKey  SET NOT NULL;
ALTER TABLE tpl_userid ALTER COLUMN Active   SET NOT NULL;
ALTER TABLE tpl_userid ALTER COLUMN Active   SET DEFAULT(TRUE); 