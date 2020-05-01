---
title: "Testing"
description: Guide on writing unit tests for moor databases
---

Flutter apps using moor can always be tested with [integration tests](https://flutter.dev/docs/cookbook/testing/integration/introduction)
running on a real device. This guide focusses on writing unit tests for a database written in moor.
Those tests can be run and debugged on your computer without additional setup, you don't a
physical device to run them.

## Setup
In addition to the moor dependencies you already have, add `moor_ffi` as a dev dependency. If you're already using `moor_ffi`
as a regular dependency, you can skip this.
```yaml
dev_dependencies:
  moor_ffi: ^0.5.0 # or latest version
```

For this guide, we're going to test a very simple database that stores user names. The only important change from a regular moor
database is the constructor: We make the `QueryExecutor` argument explicit instead of having a no-args constructor that passes
a `FlutterQueryExecutor` to the superclass.
```dart
import 'package:moor/moor.dart';

part 'database.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

@UseMoor(tables: [Users])
class MyDatabase extends _$MyDatabase {
  MyDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  /// Creates a user and returns their id
  Future<int> createUser(String name) {
    return into(users).insert(UsersCompanion.insert(name: name));
  }

  /// Changes the name of a user with the [id] to the [newName].
  Future<void> updateName(int id, String newName) {
    return update(users).replace(User(id: id, name: newName));
  }

  Stream<User> watchUserWithId(int id) {
    return (select(users)..where((u) => u.id.equals(id))).watchSingle();
  }
}
```

{{% alert title="Installing sqlite" %}}
We can't distribute an sqlite installation as a pub package (at least
not as something that works outside of a Flutter build), so you need
to ensure that you have the sqlite3 shared library installed on your
system. On macOS, it's installed by default.
On Linux, you can use the `libsqlite3-dev` package on Ubuntu and the 
`sqlite3` package on Arch (other distros will have similar packages).
On Windows, you can [download sqlite](https://www.sqlite.org/download.html)
and extract `sqlite3.dll` into a folder that's in your `PATH` environment
variable.
{{% /alert %}}

## Writing tests

We can create an in-memory version of the database by using a 
`VmDatabase.memory()` instead of a `FlutterQueryExecutor`. A good
place to open the database is the `setUp` and `tearDown` methods from
`package:test`:
```dart
import 'package:moor_ffi/moor_ffi.dart';
import 'package:test/test.dart';
// the file defined above, you can test any moor database of course
import 'database.dart'; 

void main() {
  MyDatabase database;

  setUp(() {
    database = MyDatabase(VmDatabase.memory());
  });
  tearDown(() async {
    await database.close();
  });
}
```

With that setup in place, we can finally write some tests:
```dart
test('users can be created', () async {
  final id = await database.createUser('some user');
  final user = await database.watchUserWithId(id).first;

  expect(user.name, 'some user');
});

test('stream emits a new user when the name updates', () async {
  final id = await database.createUser('first name');

  final expectation = expectLater(
    database.watchUserWithId(id).map((user) => user.name),
    emitsInOrder(['first name', 'changed name']),
  );

  await database.updateName(id, 'changed name');
  await expectation;
});
```