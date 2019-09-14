# Database Privileges Management

Privileges are great deal in Database Management. [PostgreSQL][1] offers several layers of security, this article focuses on **Database Privileges Management** using [Data Control Language][2] (DCL).

We present in this article a methodology for Database Privileges Management that relies on:

- [Role][3] [distinction between group and user][4];
- [Partially ordered set][5] and underlying [Hasse Diagram][6];
- [Role Privilege Inheritance][7].

[1]: https://www.postgresql.org/
[2]: https://en.wikipedia.org/wiki/Data_control_language
[3]: https://www.postgresql.org/docs/current/static/database-roles.html
[4]: https://www.postgresql.org/docs/current/static/role-attributes.html
[5]: https://en.wikipedia.org/wiki/Partially_ordered_set
[6]: https://en.wikipedia.org/wiki/Hasse_diagram
[7]: https://www.postgresql.org/docs/current/static/role-membership.html

## Roles

PostgreSQL natively introduces a distinction between **group** and **user** roles (this is not [SQL Standards][11] but very handy).
Both can be [created with the DDL statement][10] `CREATE ROLE`. The philosophy is the following:

- **Groups:** roles that cannot directly connect the database, but are granted to access dedicate Database Objects.
Groups are *logical collections of privileges* granted on Database Objects.

  ```sql
  CREATE ROLE manager INHERITS NOLOGIN;
  ```

  Usual names for groups are *job positions* or *dedicated functions* such as: `manager`, `supervisor`, `administrator`. They are not specific users, rather they are generic roles with associated privileges on Database Objects.
  
  > Note: Groups are vertices of the Hasse Diagram. The partial order is determined by the privilege elevation of DDL and DML they can execute on Object Database.
 
- **Users:** roles that can login but are not directly granted to access Database Objects, instead they inherit privileges from groups.

  Usual names for users are *session or login names*, *nicknames* or *job names* such as: `veronika`, `morgan`, `deamon` or `webservice`. They endorse a real identity (physical or virtual) for a human being or a software that must connect the Database and perform specific tasks with dedicated objects. They do not have associated privileges, rather they belong to groups.
  
  ```sql
  CREATE morgan INHERITS LOGIN PASSWORD '***'; 
  ```
  
  > Note: Users are also vertices, they extend the Hasse Diagram to a complete privileges graph. This extension may imply the loss of the maximal element.

[10]: https://www.postgresql.org/docs/current/static/sql-createrole.html
[11]: https://en.wikipedia.org/wiki/SQL

## Hasse Diagram

### Inheritance

[PostgreSQL privileges system][20] allows administrators to build a [Hasse Diagram][21] using inheritance, hence:

- *roles* as **vertices**;
- and *grant privilege* between two vertices is **edges**.

[20]: https://www.postgresql.org/docs/current/static/user-manag.html
[21]: https://en.wikipedia.org/wiki/Hasse_diagram

Bellow an example of an edge creation making `node1` inherit from `node0` thus introducing a partial order between that two roles.

```sql
CREATE ROLE manager INHERITS;    -- Hasse Diagram Vertex
CREATE ROLE chief INHERITS;      -- Hasse Diagram Vertex
GRANT manager TO chief;          -- Hasse Diagram Edge, defining a partial order, such as: chief >~ manager
```

It means that `chief` does have its own privileges, and it also inherits of `manager` privileges.

Because of inheritance, administrator can easily model and enforce a partial order to group roles by building such a diagram. This is very helpful because:

- it creates a logical and robust structure that is clear, understandable with known properties;
- it decouples logical roles (groups) with object privileges from identity roles (users) that are not directly granted to access objects;
- it eases modification of authorizations to people working on the database without having to redefine permissions to objects.

### Minimal & Maximal Elements

It is convenient to define a minimal and a maximal elements in a Hasse Diagram, our methodology uses them:

- a *minimal element* called `nobody` without any privileges, it cannot even connect the database;
- a *maximal element* (called `superuser`) with super-user privileges (this role also owns all system objects).

Note: It is important to completely ban the system role `public` because:

- it has defaut privileges: `CONNECT` on database and `USAGE` on schemas;
- all roles automatically inherits from it.

#### Partial Order

Privileges are relations between roles. It may induce a partial order among roles. If this property is present, Hasse Diagram can be built to represent the [poset][22]. Order is partial because not all roles pairs can be compared. This assumption can be shown on the figure bellow.

[22]: https://en.wikipedia.org/wiki/Partially_ordered_set

### Privilege Levels

SQL Standards and PostgreSQL language define [several privilege levels][30] that may fall within following categories:

[30]: https://www.postgresql.org/docs/current/static/sql-grant.html

1. **Database Connection:**
   1. **`REVOKE`**: `public` and `nobody` roles are disabled by revoking all their privileges on **`DATABASE`**;
   1. **`CONNECT`**: granted to `anybody` on **`DATABASE`**;
1. **Data Selection:**
   1. **`USAGE`**: granted to group roles on specific **`SCHEMAS`** allowing catalogue lookups;
   1. **`SELECT`**: granted to group roles on specific **`TABLES`** allowing data selection;
   1. **`EXECUTE`**: granted to group roles on specific **`FUNCTIONS`** allowing function execution provided underlying object privileges are granted;
1. **Data Edition:**
   1. **`INSERT`**: granted to group roles on specific **`TABLES`** allowing data insertion;
   1. **`UPDATE`**: granted to group roles on specific **`TABLES`** allowing data modification;
   1. **`EXECUTE`**: granted to group roles on specific **`FUNCTIONS`** allowing function execution provided underlying object privileges are granted;
1. **Data Deletion:**
   1. **`DELETE`**: granted to group roles on specific **`TABLES`** allowing data deletion;
   1. **`EXECUTE`**: granted to group roles on specific **`FUNCTIONS`** allowing function execution provided underlying object privileges are granted;
1. **Object Management:**
   1. **`CREATE`**: granted to `superuser` allowing object creation;
   1. **`DROP`**: granted to `superuser` allowing object destruction.

Above classification is not absolute. It is just an example that well fits Hasse Diagram structure. Of course, there are another possible classifications, for example when data must be inserted but not selected or updated but not inserted. And those properties can also be formalized with a Hasse Diagram.

## Basic Setup

Following figure shows a basic privileges setup for a small production database:

<div><img src="../../media/figures/privileges/dml.png" width="50%" /></div>
<div><img src="../../media/figures/privileges/hasse.png" width="50%" /></div>
<div><img src="../../media/figures/privileges/graph.png" width="50%" /></div>

Hasse Diagram above eases privileges administartion, we directly see:

- A minimal vertex `nobody` which has no privileges on database;
- A vertex `anybody` required to connect the database;
- A collection of vertices (`student`, `scientific`, `technician`, `administrative`, `revisor`, `www`) that can use dedicated schemas and select on dedicated tables;
- A collection of vertices (`manager`, `supervisor`, `auditor`) that can insert and update dedicated tables;
- A collection of vertices (`chief`, `administrator`) that can delete on dedicated tables;
- A maximal vertex `superuser` which can create and drop object in database.

In this setup, there is partial order (following privilege levels) defined among those vertices, there are pairs of vertices that can be compared and ordered:

- In terms of privilege levels, following roles can be ordered as follow: `superuser` > `chief` > `manager` > `scientific` > `anybody` > `nobody`;
- But the order is partial, because we cannot compare some pairs of roles, such as: `chief` ? `administartor`. They both are superior than `anybody` and inferor than `superuser`, but there is no way to determine which is greater than the other. In the same fashion, there is no way to order `scientific`, `student` and `technician`, they stand at the same privilege level, but they are not comparable.


