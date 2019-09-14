# Deploy PostgreSQL as RDBMS

## Requirements

> To complete this article, we assume you are running a Debian-Like system (`version >= 7.0`) and you are blessed with `sudo`.

First we need PostgreSQL to be installed our server, bare setup should be:

```sh
sudo apt-get update
sudo apt-get install postgresql-9.5 postgresql-common postgresql-contrib
```

You will find more interesting related packages (Postgis, etc.) with: 

```sh
sudo apt-get update
sudo apt-cache search postgresql
```

## Group membership

When PostgreSQL installs, it creates eponymous unix account and group `postgres`.
In some setup, it could ease administration task to be member of the `postgres` group.
Check out if you are already enroled:

```sh
groups

airproject [...] postgres [...]
```

Or register if needed:

```sh
sudo usermod -a -G postgres airproject
```

Don't forget the `-a` switch, and mind the case with `-G`, read [`man usermod`][100] to understand why.

[100]: http://www.delafond.org/traducmanfr/man/man8/usermod.8.html

## Cluster creation

After installing PostgreSQL, there is a default cluster, called `main` and owned by user `postgres`, **running locally** and **listening  on port `5432`**. Check out clusters with `pg_lsclusters`:

```sh
pg_lsclusters

Ver Cluster  Port Status Owner    Data directory                   Log file
9.5 main     5432 online postgres /var/lib/postgresql/9.5/main     /var/log/postgresql/postgresql-9.5-main.log
```

We create a cluster `newproject` listening on port `5050`. We want the cluster to belong to the `airproject` unix user (it eases administration and relax the constraint to be member of the `postgres` group): 

```sh
sudo pg_createcluster -u airproject -p 5050 9.5 newproject

Creating new cluster 9.5/newproject ...
  config /etc/postgresql/9.5/newproject
  data   /var/lib/postgresql/9.5/newproject
  locale en_US.UTF-8
  socket /tmp
  port   5050
```

The cluster has been created and its state is `down`:

```sh
pg_lsclusters

Ver Cluster    Port Status Owner      Data directory                     Log file
9.5 main       5432 online postgres   /var/lib/postgresql/9.5/main       /var/log/postgresql/postgresql-9.5-main.log
9.5 newproject 5050 down   airproject /var/lib/postgresql/9.5/newproject /var/log/postgresql/postgresql-9.5-newproject.log
```

## Cluster Activation

To `start` the cluster, you can make use of `postgresql-contrib` commands:

```sh
pg_ctlcluster 9.5 newproject start

Warning: the cluster will not be running as a systemd service. Consider using systemctl:
  sudo systemctl start postgresql@9.5-newproject
```

But, from now, this is the old way to start a cluster. On Debian (`version >= 8`), it is better to use service manager `systemd` to handle clusters. This is why we have got a warning, telling us to change our methodology.

### Cluster registration

Register the cluster as a service with `systemctl`:

```sh
sudo systemctl enable postgresql@9.5-newproject

Created symlink from /etc/systemd/system/multi-user.target.wants/postgresql@9.5-newproject.service to /lib/systemd/system/postgresql@.service.
```

Then start the cluster:

```sh
sudo systemctl start postgresql@9.5-newproject
```

And check its status:

```sh
systemctl status postgresql@9.5-newproject.service
● postgresql@9.5-newproject.service - PostgreSQL Cluster 9.5-newproject
   Loaded: loaded (/lib/systemd/system/postgresql@.service; enabled; vendor preset: enabled)
   Active: active (running) since Tue 2018-01-02 14:43:06 UTC; 38s ago
 Main PID: 2084 (postgres)
   CGroup: /system.slice/system-postgresql.slice/postgresql@9.5-newproject.service
           ├─2084 /usr/lib/postgresql/9.5/bin/postgres -D /var/lib/postgresql/9.5/newproject -c config_file=/etc/postgresql/9.5/newproje
           ├─2086 postgres: checkpointer process
           ├─2087 postgres: writer process
           ├─2088 postgres: wal writer process
           ├─2089 postgres: autovacuum launcher process
           └─2090 postgres: stats collector process

Jan 02 14:43:03 penelope systemd[1]: Starting PostgreSQL Cluster 9.5-newproject...
Jan 02 14:43:06 penelope systemd[1]: Started PostgreSQL Cluster 9.5-newproject.
Jan 02 14:43:17 penelope systemd[1]: Started PostgreSQL Cluster 9.5-newproject.
```

Double check with PostgreSQL commodities:

```sh
pg_lsclusters

Ver Cluster    Port Status Owner      Data directory                     Log file
9.5 main       5432 online postgres   /var/lib/postgresql/9.5/main       /var/log/postgresql/postgresql-9.5-main.log
9.5 newproject 5050 online airproject /var/lib/postgresql/9.5/newproject /var/log/postgresql/postgresql-9.5-newproject.log
```

Cluster is running now. It is owned by Unix User `airproject` and there is an *alter-ego* PostgreSQL Super User `airproject` created. 

## Cluster Setup

### Tablespace

Cluster tablespace resides by default in `/var/lib/postgresql/9.5`:

```sh
ls -l /var/lib/postgresql/9.5

drwx------ 19 postgres   postgres   4096 Aug 30 13:06 main
drwx------ 19 airproject airproject 4096 Jan  2 14:46 newproject
```

We can see the new cluster is owned by `airproject` Unix User. You should never edit by yourself files held in those directory. Doing so will likely corrupt your database.

### Cluster Settings

And cluster settings resides in `/etc/postgresql/9.5`:

```sh
ls -l /etc/postgresql/9.5

drwxr-xr-x 2 postgres   postgres   4096 Aug 30 13:07 main
drwxr-xr-x 2 airproject airproject 4096 Jan  2 14:38 newproject
```

Main settings files are:

```sh
ls -lh /etc/postgresql/9.5/newproject

[...]
-rw-r----- 1 airproject airproject 4.6K Jan  2 14:38 pg_hba.conf
-rw-r--r-- 1 airproject airproject  21K Jan  2 14:38 postgresql.conf
[...]
```

#### Network setup

At this point, the cluster listen only on the loopback (localhost).
We want to bind the server to a network card in order to get external access to the cluster.

First check out your network card settings:

```sh
ifconfig

ens160    Link encap:Ethernet [...]
          inet addr:10.86.40.180 [...]
```

Edit `postgresql.conf` file to bind the server to the network card:

```sh
nano /etc/postgresql/9.5/newproject/postgresql.conf
```

Basic setup must at least contain those lines:

```sh
[...]
listen_addresses = '*'                  # what IP address(es) to listen on;
[...]
port = 5050                             # (change requires restart)
max_connections = 100                   # (change requires restart)
[...]
unix_socket_directories = '/var/run/postgresql' # comma-separated list of directories
```

Or you may restrict the server to a dedicated IP:

```sh
[...]
listen_addresses = '10.86.40.180'       # what IP address(es) to listen on;
[...]
```

In some setup, you may need to force `postgresql@9.5-newproject.service` to wait for `network-online.target` before starting the service. If your Cluster does not start after a hard reboot (machine), you should investigate this [issue][20]. 

[20]: https://unix.stackexchange.com/questions/126009/cause-a-script-to-execute-after-networking-has-started

#### Access Control List

Now we need to define which users can connect and how they can connect. In this basic setup, we allow:

 - Role `airproject` to connect all database locally using its *alter-ego* Unix authentication (`peer` mode);
 - And all other roles to connect from the LAN `10.0.0.0/8` using their passwords (`md5` mode).

```sh
nano /etc/postgresql/9.5/newproject/pg_hba.conf

[...]
# Database administrative login by Unix domain socket
local   all             airproject                              peer
[...]
# IPv4 local connections:
host    all             all             10.0.0.0/8              md5
[...]
```

#### Apply the configuration

After having those file edited, we need to restart the PostgreSQL service.

```sh
sudo systemctl restart postgresql@9.5-newproject.service
```

Check the Network Binding is effective:

```sh
netstat -an | grep 5050

tcp        0      0 10.86.40.180:5050       0.0.0.0:*               LISTEN
unix  2      [ ACC ]     STREAM     LISTENING     55823    /var/run/postgresql/.s.PGSQL.5050
```

And unix socket have been created:

```sh
ls -la /var/run/postgresql/

[...]
drwxr-s---  2 airproject airproject  80 Jan  2 15:14 9.5-newproject.pg_stat_tmp
-rw-r--r--  1 airproject postgres     5 Jan  2 15:14 9.5-newproject.pid
[...]
srwxrwxrwx  1 airproject postgres     0 Jan  2 15:14 .s.PGSQL.5050
-rw-------  1 airproject postgres    76 Jan  2 15:14 .s.PGSQL.5050.lock
[...]
```

If you don't see Unix Socket `.s.PGSQL.5050`, check your `postgresql.conf` file and ensure `unix_socket_directories` points to `'/var/run/postgresql'`.

#### Create Super User Password

Now we connect as `airproject` our cluster using `psql` to connect the `postgres` database on port `5050`. And setup the Super User password in order to be able to use this role in remote mode (eg. using PgAdmin on a desktop machine).

```sh
psql -p 5050 -d postgres

postgres=# \conninfo
You are connected to database "postgres" as user "airproject" via socket in "/var/run/postgresql" at port "5050".

postgres=# \password
Enter new password:
Enter it again:

postgres=# \quit
```

#### Firewall

If you are running a firewall, you will also need to add a rule to allow external traffic to your cluster:

```sh
nano /etc/iptables/rules.v4

[...]
-A INPUT -s 10.0.0.0/8   -p tcp -m tcp --sport 1024:65535 --dport 5050 -m state --state NEW,ESTABLISHED -j ACCEPT
[...]
```

Restart the firewall:

```sh
sudo systemctl restart netfilter-persistent.service
```

At this point, your cluster is setup, running and should be accessible from all machines in the scope of the LAN.

## Create Database

Finally we create a Database called `airproject` in our cluster to get our data self contained. Do not mess up with the `postgres` Database, just let it alone.

We connect the administrative database `postgres` as `airproject`:

```sh
psql -p 5050 -d postgres
psql (9.5.10)
Type "help" for help.
postgres=# \conninfo
You are connected to database "postgres" as user "airproject" via socket in "/var/run/postgresql" at port "5050".
```

We [create a Database][30]:

[30]: https://www.postgresql.org/docs/current/static/sql-createdatabase.html

```psql
postgres=# CREATE DATABASE airproject;
CREATE DATABASE
```

And [revoke all privileges][31] from `public` user:

[31]: https://www.postgresql.org/docs/current/static/sql-revoke.html

```psql
postgres=# REVOKE ALL ON DATABASE airproject FROM public;
REVOKE
postgres=#\quit
```

Your cluster and its first database are ready. Don't forget to disconnect the `postgres` administrative database and reconnect the righful database from any machine and with any client you like:

```sh
psql -h 10.86.40.180 -p 5050 -U airproject -d airproject

airproject=# \conninfo
You are connected to database "airproject" as user "airproject" via socket in "10.86.40.180" at port "5050".
```

## What's next

We have:

 1. Created a PostgreSQL cluster owned by a Unix User;
 2. Registred the Cluster as a service with `systemd`;
 3. Setup PostgreSQL cluster to be accessed into the LAN;
 4. Create a new Database for a new project.
 
Next steps are:

 - Design a Privileges Policy: create Roles and Groups;
 - Design a Datamodel and implement it: create Schemas, Tables, etc.
 - Host data and perform operations on it.
