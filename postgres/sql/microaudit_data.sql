-- Some dummy table for testing purposes:
DROP TABLE IF EXISTS channels CASCADE;
CREATE TABLE channels(
    Id          INTEGER    NOT NULL
   ,UserKey     TEXT       NOT NULL
   ,Active      BOOLEAN    NOT NULL   DEFAULT(TRUE)
    ---
   ,PRIMARY KEY(Id)
   ,UNIQUE(UserKey)
);

-- Perform some operations:

-- Insert records:
INSERT INTO channels(
SELECT C.Id, 'C-' || C.Id
FROM generate_series(1, 300, 10) AS C(Id)
);

-- Delete some Records:
DELETE FROM channels WHERE id BETWEEN 30 AND 80;

-- Update a record:
UPDATE channels
SET UserKey = 'C-x'
WHERE id = 21;

-- Upsert bunch of records:
-- Also works with an echo (INSERT and UPDATE) for existing row!
WITH
D AS (
SELECT C.Id, 'D-' || C.Id AS ukey
FROM generate_series(201, 400, 10) AS C(Id)
)
INSERT INTO Channels (SELECT * FROM D)
ON CONFLICT (Id)
DO UPDATE
SET UserKey = EXCLUDED.UserKey;
