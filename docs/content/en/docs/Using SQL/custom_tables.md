---
title: "Tables from SQL"
weight: 20
description: Generate tables from `CREATE TABLE` statements.
---

{{% alert title="Experimental feature" %}}
At the moment, creating table classes from `CREATE TABLE` statements is an experimental feature.
If you run into any issues, please create an issue and let us know, thanks!
{{% /alert %}}

With moor, you can specify your table classes in Dart and it will generate matching
`CREATE TABLE` statements for you. But if you prefer to write `CREATE TABLE` statements and have
moor generating fitting Dart classes, that works too.

To use this feature, create a (or multiple) `.moor` file somewhere in your project. You can fill
them with create table statements:
```sql
 CREATE TABLE states ( 
     id INT NOT NULL PRIMARY KEY AUTOINCREMENT, 
     name TEXT NOT NULL 
 ); 
  
 CREATE TABLE experiments ( 
     id INT NOT NULL PRIMARY KEY AUTOINCREMENT, 
     description TEXT NOT NULL, 
     state INT REFERENCES states(id) ON UPDATE CASCADE ON DELETE SET NULL 
 ) 
```

Then, import these tables to your database with:
```dart
@UseMoor(include: {'experiments.moor'})
class ExperimentsDb extends _$ExperimentsDb {
```

All the tables will then be available inside your database class, just like they
would be if you wrote them in Dart. If you want to use this feature on an DAO,
you'll also need to `include` the .moor file on that class. Moor supports both
relative imports (like above) and absolute imports (like `package:your_app/src/tables/experiments.moor`)
Of course, this feature works perfectly together with features like generated
custom queries and query-streams.