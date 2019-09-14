DROP SCHEMA IF EXISTS test CASCADE;
CREATE SCHEMA test;


CREATE TABLE test.a(
    id SERIAL PRIMARY KEY
   ,Userkey TEXT NOT NULL UNIQUE
);

CREATE TABLE test.b(
    id SERIAL PRIMARY KEY
   ,fid INTEGER REFERENCES test.a(id) ON DELETE CASCADE
   ,Userkey TEXT NOT NULL UNIQUE
);

INSERT INTO test.a VALUES
(1, 'jeanbono'), (2, 'tofeke'), (3, 'biloute');


INSERT INTO test.b VALUES
(1, 1, 'green tea'), (2, 1, 'moleke'), (3, 2, 'poteke');

--https://www.postgresql.org/docs/current/static/ddl-constraints.html
SELECT * FROM test.a AS A FULL OUTER JOIN test.B AS B ON (A.Id = B.fid);

DELETE FROM test.a WHERE id=1;