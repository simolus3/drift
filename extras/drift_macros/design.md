## Drift with macros - design notes

Current blockers:

- The macro specs say we should be able to pass types as `Identifiers` and code
  as `Code`. That appears to be unimplemented at the moment?
  We can't implement the `@DriftDatabase` annotation without it.
- New types declared by macros are not resolved by the frontend at all??

## Core design idea

The core query builder APIs in the `drift` package turned out to be a good
abstraction for writing SQL and defining schemas.
Drift's macro support should be compatible with them (perhaps with minor
modifications where that makes sense). This means that augmented classes from
macros should implement existing classes like `TableInfo`.

However, drift's model of declaring tables in Dart and then generating table
classes for that turned out to be flawed: It makes these generated classes
inaccessible for other macros/builders to modify them, thus forcing drift to
implement common functionality like `==`, `hashCode` or even JSON serialization
itself instead of being able to rely on other packages for that.
With macros, we have a chance to finally get that right. Instead of declaring
tables with a custom Dart DSL, we can embrace macros for everything and declare
tables by writing annotated row classes, similar to how Android's Room library
is doing it:

```dart
@Table()
class User {
  @Column(primaryKey: true)
  final int id;
  final String name;

  User(this.id, this.name);
}

@Table(
  primaryKey: {#userA, #userB},
)
class Friendship {
  @References(Users, #id)
  final int userA;
  @References(Users, #id)
  final int userB;

  Friendship(this.userA, this.userB);
}
```

## SQL support

By augmenting existing methods, we can support custom queries with annotations
on methods of a database or accessor class:

```dart
@DriftDatabase(tables: [Users, Friendships])
final class MyDatabase {
  @Query(r'SELECT * FROM User m ORDER BY (SELECT COUNT(*) FROM Friendship WHERE userA = m.id OR userB = m.id) DESC LIMIT $limit')
  Selectable<User> mostPopularUsers(Limit? limit);
}
```

Since we can emit diagnostics in macros, we can even highlight invalid SQL syntax
right in the query string.

We can still generate "default" row classes for results by checking whether the
type identifier can be resolved.

```dart
@DriftDatabase(tables: [Users, Friendships])
final class MyDatabase {
  // Generating into existing pre-defined type
  @Query(r'SELECT a.**, b.** FROM Friendship INNER JOIN ...')
  Selectable<({User a, User b})> friends();

  // Generating into implicitly defined type
  @Query('...')
  Selectable<FriendshipWithUser> friends2();
}
```

We can also define tables from SQL, which could look like this:

```dart
@Table(sql: '''
  CREATE TABLE users (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT,
  ) STRICT;
''')
class User {
  final int id;
  final String name;

  User(this.id, this.name);
}
```

### Drift file support

At the moment, macros have no way to resolve external files. So we have to figure
something out here.

## CLI support

Drift supports exporting database schemas to generate migration verification
tools.
Duplicating table analysis logic with a CLI / macros backend sounds like a lot
of work, but we can probably avoid this if macros had a way to add annotations
to classes (jakemac once told me that's supposed to be supported). Then we
could serialize resolved tables to json, dump that in an annotation and read
that via the analyzer API which includes augmented elements.

