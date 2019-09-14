# Connect PostgreSQL Database

This article explains how to connect PostgreSQL database using:
 - [`psql`](https://www.postgresql.org/docs/current/static/app-psql.html): a CLI client that allow user to redirect SQL scripts or pipe valid streams to it;
 - [`pgAdmin`](https://www.pgadmin.org/): a GUI client that allow user to explore, visualize and manage databases;
 - [`psycopg2`](http://initd.org/psycopg/docs/install.html): a [`python3`](https://www.python.org/) library allowing user to connect PostgreSQL in Python scripts.

## Connection String

In order to connect a database we need a valid [connection string](https://en.wikipedia.org/wiki/Connection_string). A connection string is a set of parameters that properly defines:

- [x] a Machine Server (hardware) called `host`, it can be an `ip` or any valid domain name;
- [x] a Database Server (software, service) listening at specific `port`. PostgeSQL names it as `cluster`;
- [x] a Database (session database) referenced as `database`;
- [x] a user name (session login) called `user`;
- [x] credentials for authentication:
  - [x] a unix session using `peer` mode;
  - [x] a password using `md5` mode;
  - [x] a set of certificates using `cert` mode.
- [x] a `protocol` defining communication (generaly implicit within the client scope);
- [ ] a set of options:
  - [ ] SSL encryption;
  - [ ] compression.

We define bellow a trial connection:

- [x] **`host`** (`string`): **penelope**  (a virtual server with a domain name);
- [x] **`port`** (`integer`): **5002** (a cluster called `geomatic` listening);
- [x] **`database`** (`string`): **airproject** (a trial database);
- [x] **`user`** (`string`): **jlandercy** (someone able to connect);
- [x] **`password`** (`string`): **\*\*\*** (a known sequence anyone should never guess);
- [x] **`protocol`** (`string`): **postgresql** (native interface, implicit);
- [x] **`sslmode`** (`string`): **require** (we want connection encrypted);

### URI Style

PostgreSQL complies with [URI](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier) standards, therefore a valid connection string for PostgreSQL can be an URI of the form:

```
protocol:[//[user[:password]@]host[:port]][/database][?option-key][#option-value]
```

Using the trial connection above, it translates to:

```
postgresql://jlandercy:***@penelope:5002/airproject?sslmode=require
```

### Identify Cluster

It is very important to properly identify the cluster before connecting it. Missing this step can lead to great troubles.
By default, many client will assume a cluster running on `localhost` listening at port `5432`.

If we have adminstrative privileges on several clusters (lets say some are clones of production cluster for development purposes), it is easy to connect the wrong database and totally wipe out the production database instead of the development one. This probably will make you feel bad. Remember:

> At the connection stage, nothing looks more like a database than another database.

Therfore we strongly advise user **to ever setup port in connection string**, it forces us to explicitly name the datasource we want to connect and avoid mistakes.

### Credentials

- [x] Do not choose a dummy predictable password;
- [x] Do not hardcode password;
- [x] Do not give your credential to another, ask them having one! Your admin will be pleased;
- [x] Secure certificate keys (`chmod`);
- [x] Revoke certificate if compromised, get a fresh one. Contact your admin;
- [x] Do not send password in clear over network, require at least SSL for connection.

## PostgreSQL Client

Client `psql` is the native terminal to communicate with PostgreSQL. If password is not provided in the connection string it will be prompted in order to complete the connection.

To connect the database using the interative terminal, just invoke `psql` with a valid connection string:

```shell
psql "postgresql://jlandercy@penelope:5002/airproject?sslmode=require"
Password: ***
psql (9.5.8)
SSL connection (cipher: ECDHE-RSA-AES256-SHA, bits: 256)
Type "help" for help.

airproject=> \conninfo
You are connected to database "airproject" as user "jlandercy" on host "penelope" at port "5002".
airproject=> \quit
```

We can use `psql` internal command `\conninfo` to double check we have connected the rightful source.

### Command Line Style

It is also possible to use `psql` switches, to connect database, the following syntax is equivalent to the previous:

```shell
psql -h penelope -p 5002 -d airproject -U jlandercy -W
```

### Redirection with `psql`

The CLI `psql` is [POSIX][1] compliant, we can use its [Standard Input][2] `std::in` to execute valid SQL code instead of opening a new interactive terminal tight to keyboard.

It can be done either by [redirecting][3] a script:

```bash
psql [connections] < "script.sql"
```

Or by [pipelining][4] a stream from a command:

```bash
command [options] | psql [connections]
```

This is very helpful to perform administrative operations or specialized imports.

[1]: https://en.wikipedia.org/wiki/POSIX
[2]: https://en.wikipedia.org/wiki/Standard_streams
[3]: https://en.wikipedia.org/wiki/Redirection_(computing)
[4]: https://en.wikipedia.org/wiki/Pipeline_(Unix)

## pgAdmin Client

Equivalent connection setup for pgAdmin client is:

<div>
<div><img src="../../media/screenshots/pgadmin001.png" width="25%" /></div>
<div><img src="../../media/screenshots/pgadmin002.png" width="25%" /></div>
</div>

Then we can connect the database and explore its objects using pgAdmin GUI:

![pgAdmin Connection](../../media/screenshots/pgadmin003.png)

This client is helpful to get a complete overview of the cluster and its objcets.

## Python Client

The `psycopg2` library fulfills the Python 3 `connect()` Interface for database connection. First we import the library:

```python
import psycopg2
```

Then we connect the database using the interface:

```python
dbcon = psycopg2.connect(
    host='penelope', port=5002, dbname='airproject'
   ,user='jlandercy', password='***'
   ,sslmode='require'
)
```

It also works with URI:

```python
dbcon = psycopg2.connect("postgresql://jlandercy:***@penelope:5002/airproject?sslmode=require")
```

Afterward we can create cursor to perform queries:

```python
dbcur = dbcon.cursor()
dbcur.execute("SELECT * FROM dummy LIMIT 100;")
rows = dbcur.fetchall()
```

From there we can build our own client application.
