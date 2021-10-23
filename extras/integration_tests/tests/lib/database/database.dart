import 'dart:convert';

import 'package:json_annotation/json_annotation.dart' as j;
import 'package:moor/moor.dart';

import 'package:tests/data/sample_data.dart' as people;

part 'database.g.dart';

class Users extends Table {
  /// The user id
  IntColumn get id => integer().autoIncrement()();

  // The user name
  TextColumn get name => text()();

  /// The users birth date
  ///
  /// Mapped from json `born_on`
  @JsonKey('born_on')
  DateTimeColumn get birthDate => dateTime()();

  BlobColumn get profilePicture => blob().nullable()();

  TextColumn get preferences =>
      text().map(const PreferenceConverter()).nullable()();
}

class Friendships extends Table {
  IntColumn get firstUser => integer()();
  IntColumn get secondUser => integer()();

  BoolColumn get reallyGoodFriends =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {firstUser, secondUser};
}

@j.JsonSerializable()
class Preferences {
  bool receiveEmails;

  Preferences(this.receiveEmails);

  factory Preferences.fromJson(Map<String, dynamic> json) =>
      _$PreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$PreferencesToJson(this);
}

class PreferenceConverter extends TypeConverter<Preferences, String> {
  const PreferenceConverter();
  @override
  Preferences? mapToDart(String? fromDb) {
    if (fromDb == null) {
      return null;
    }
    return Preferences.fromJson(json.decode(fromDb) as Map<String, dynamic>);
  }

  @override
  String? mapToSql(Preferences? value) {
    if (value == null) {
      return null;
    }

    return json.encode(value.toJson());
  }
}

@UseMoor(
  tables: [Users, Friendships],
  queries: {
    'mostPopularUsers': 'SELECT * FROM users u '
        'ORDER BY (SELECT COUNT(*) FROM friendships '
        'WHERE first_user = u.id OR second_user = u.id) DESC LIMIT :amount',
    'amountOfGoodFriends':
        'SELECT COUNT(*) FROM friendships f WHERE f.really_good_friends AND '
            '(f.first_user = :user OR f.second_user = :user)',
    'friendshipsOf': ''' SELECT 
          f.really_good_friends, user.**
       FROM friendships f
         INNER JOIN users "user" ON "user".id IN (f.first_user, f.second_user) AND
             "user".id != :user
       WHERE (f.first_user = :user OR f.second_user = :user)''',
    'userCount': 'SELECT COUNT(id) FROM users',
    'settingsFor': 'SELECT preferences FROM users WHERE id = :user',
    'usersById': 'SELECT * FROM users WHERE id IN ?',
    'returning': 'INSERT INTO friendships VALUES (?, ?, ?) RETURNING *;',
  },
)
class Database extends _$Database {
  /// We make the schema version configurable to test migrations
  @override
  final int schemaVersion;

  Database(DatabaseConnection e, {this.schemaVersion = 2}) : super.connect(e);

  Database.executor(QueryExecutor db)
      : this(DatabaseConnection.fromExecutor(db));

  /// It will be set in the onUpgrade callback. Null if no migration occurred
  int? schemaVersionChangedFrom;

  /// It will be set in the onUpgrade callback. Null if no migration occurred
  int? schemaVersionChangedTo;

  MigrationStrategy? overrideMigration;

  @override
  MigrationStrategy get migration {
    return overrideMigration ??
        MigrationStrategy(
          onCreate: (m) async {
            await m.createTable(users);
            if (schemaVersion >= 2) {
              // ensure that transactions can be used in a migration callback.
              await transaction(() async {
                await m.createTable(friendships);
              });
            }
          },
          onUpgrade: (m, from, to) async {
            schemaVersionChangedFrom = from;
            schemaVersionChangedTo = to;

            if (from == 1) {
              await m.createTable(friendships);
            }
          },
          beforeOpen: (details) async {
            if (details.wasCreated) {
              // make sure that transactions can be used in the beforeOpen callback.
              await transaction(() async {
                await batch((batch) {
                  batch.insertAll(
                      users, [people.dash, people.duke, people.gopher]);
                });
              });
            }
          },
        );
  }

  Future<void> deleteUser(User user, {bool fail = false}) {
    return transaction(() async {
      final id = user.id;
      await (delete(friendships)
            ..where((f) => f.firstUser.equals(id) | f.secondUser.equals(id)))
          .go();

      if (fail) {
        throw Exception('oh no, the query misteriously failed!');
      }

      await delete(users).delete(user);
    });
  }

  Stream<User> watchUserById(int id) {
    return (select(users)..where((u) => u.id.equals(id))).watchSingle();
  }

  Future<User> getUserById(int id) {
    return (select(users)..where((u) => u.id.equals(id))).getSingle();
  }

  Future<int> writeUser(Insertable<User> user) {
    return into(users).insert(user);
  }

  Selectable<User> friendsOf(int id) => friendshipsOf(id).map((r) => r.user);

  Future<void> makeFriends(User a, User b, {bool? goodFriends}) async {
    var friendsValue = const Value<bool>.absent();
    if (goodFriends != null) {
      friendsValue = Value(goodFriends);
    }

    final companion = FriendshipsCompanion(
      firstUser: Value(a.id),
      secondUser: Value(b.id),
      reallyGoodFriends: friendsValue,
    );

    await into(friendships).insert(companion, mode: InsertMode.insertOrReplace);
  }

  Future<void> updateSettings(int userId, Preferences c) async {
    await (update(users)..where((u) => u.id.equals(userId)))
        .write(UsersCompanion(preferences: Value(c)));
  }
}
