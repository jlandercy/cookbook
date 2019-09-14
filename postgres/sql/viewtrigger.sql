DROP SCHEMA IF EXISTS test CASCADE;
CREATE SCHEMA test;


CREATE TABLE test.a(aid SERIAL PRIMARY KEY, auserkey TEXT NOT NULL UNIQUE);
CREATE TABLE test.b(bid SERIAL PRIMARY KEY, aid INTEGER REFERENCES test.a(aid), buserkey TEXT NOT NULL UNIQUE);

CREATE VIEW test.c AS
SELECT
    *
FROM
    test.a AS A JOIN test.b AS B USING(aid)
ORDER BY
    A.aUserKey, B.bUserKey;

SELECT * FROM test.c;
--INSERT INTO test.c VALUES(1,'test',1,'coucou');
/*
ERROR:  cannot insert into view "c"
DETAIL:  Views that do not select from a single table or view are not automatically updatable.
HINT:  To enable inserting into the view, provide an INSTEAD OF INSERT trigger or an unconditional ON INSERT DO INSTEAD rule.
*/

CREATE FUNCTION test.update_c()
RETURNS trigger AS
$BODY$
BEGIN

INSERT INTO test.a VALUES(NEW.aid, NEW.auserkey)
ON CONFLICT (aid)
DO UPDATE
SET auserkey = EXCLUDED.auserkey;

INSERT INTO test.b VALUES(NEW.bid, NEW.aid, NEW.buserkey)
ON CONFLICT (bid)
DO UPDATE
SET
aid = EXCLUDED.aid,
buserkey = EXCLUDED.buserkey;

RETURN NEW;

END;
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER update_c INSTEAD OF INSERT
ON test.c
FOR EACH ROW
EXECUTE PROCEDURE test.update_c();

INSERT INTO test.c VALUES(1,'test',1,'coucou');
INSERT INTO test.c VALUES(1,'test',1,'coucoux');
INSERT INTO test.c VALUES(2,'blabla',1,'coucoux');

DELETE FROM test.a WHERE aId = 2;
/*
ERROR:  update or delete on table "a" violates foreign key constraint "b_aid_fkey" on table "b"
DETAIL:  Key (aid)=(2) is still referenced from table "b".
*/

