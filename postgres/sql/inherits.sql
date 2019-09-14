-- Channels:
DROP TABLE IF EXISTS channels CASCADE;
CREATE TABLE channels(
    Id          INTEGER    NOT NULL
   ,UserKey     TEXT       NOT NULL
   ,Active      BOOLEAN    NOT NULL   DEFAULT(TRUE)
    ---
   ,PRIMARY KEY(Id)
   ,UNIQUE(UserKey)
);

-- Synthetic channels:
INSERT INTO channels(
SELECT C.Id, 'Channel-' || C.Id
FROM generate_series(1, 300, 10) AS C(Id)
);

-- Dataset Template:
DROP TABLE IF EXISTS dataset CASCADE;
CREATE TABLE dataset(
    Id          BIGSERIAL  NOT NULL
   ,ChannelId   INTEGER    NOT NULL
   ,TimeValue   TIMESTAMP  NOT NULL
   ,TimeRange   INTERVAL   NOT NULL
   ,FloatValue  FLOAT
    ---
   --,FOREIGN KEY(ChannelId) REFERENCES Channels(Id) [1]
);

-- Network 1 Dataset:
CREATE TABLE datanet1(
    PRIMARY KEY(Id)
   ,FOREIGN KEY(ChannelId) REFERENCES Channels(Id)
   ,CHECK(ChannelId BETWEEN 1 AND 100)
) INHERITS(dataset);

-- Network 2 Dataset:
CREATE TABLE datanet2(
    PRIMARY KEY(Id)
   ,FOREIGN KEY(ChannelId) REFERENCES Channels(Id)
   ,CHECK(ChannelId BETWEEN 101 AND 200)
) INHERITS(dataset); 

-- Insert Synthetic Data into Network 1 Dataset:
INSERT INTO datanet1(ChannelId, TimeValue, TimeRange, FloatValue) (
SELECT
   C.Id
  ,'2000-01-01'::TIMESTAMP + '00:30:00'::INTERVAL*D.x
  ,'00:30:00'::INTERVAL
  ,D.x::FLOAT
FROM
   generate_series(1, 100, 10) AS C(Id)
  ,generate_series(-10, 10) AS D(x)
);

-- Insert Synthetic Data into Network 2 Dataset:
INSERT INTO datanet2(ChannelId, TimeValue, TimeRange, FloatValue) (
SELECT
   C.Id
  ,'2000-01-01'::TIMESTAMP + '00:30:00'::INTERVAL*D.x
  ,'00:30:00'::INTERVAL
  ,D.x::FLOAT
FROM
   generate_series(101, 200, 10) AS C(Id)
  ,generate_series(-10, 10) AS D(x)
);

---------------------
-- Insert Bad Records:
---------------------

-- This works if constraint is applyed to parent table [1]:
INSERT INTO datanet1(ChannelId, TimeValue, TimeRange, FloatValue) VALUES
('25', '2010-01-01', '00:30:00', NULL);
/*
ERROR: insert or update on table "datanet1" violates foreign key constraint "datanet1_channelid_fkey"
SQL state: 23503
Detail: Key (channelid)=(25) is not present in table "channels".
*/

INSERT INTO datanet1(ChannelId, TimeValue, TimeRange, FloatValue) VALUES
('101', '2010-01-01', '00:30:00', NULL);
/*
ERROR: new row for relation "datanet1" violates check constraint "datanet1_channelid_check"
SQL state: 23514
Detail: Failing row contains (430, 101, 2010-01-01 00:00:00, 00:30:00, null).
*/