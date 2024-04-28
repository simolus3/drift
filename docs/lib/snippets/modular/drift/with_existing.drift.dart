// ignore_for_file: type=lint, invalid_use_of_internal_member
import 'package:drift/drift.dart' as i0;
import 'package:drift_docs/snippets/modular/drift/row_class.dart' as i1;
import 'package:drift_docs/snippets/modular/drift/with_existing.drift.dart'
    as i2;
import 'package:drift/internal/modular.dart' as i3;

class Users extends i0.Table with i0.TableInfo<Users, i1.User> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  Users(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  late final i0.GeneratedColumn<int> id = i0.GeneratedColumn<int>(
      'id', aliasedName, false,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY');
  static const i0.VerificationMeta _nameMeta =
      const i0.VerificationMeta('name');
  late final i0.GeneratedColumn<String> name = i0.GeneratedColumn<String>(
      'name', aliasedName, false,
      type: i0.DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  @override
  List<i0.GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  i0.VerificationContext validateIntegrity(i0.Insertable<i1.User> instance,
      {bool isInserting = false}) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.User(
      attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}id'])!,
      attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}name'])!,
    );
  }

  @override
  Users createAlias(String alias) {
    return Users(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class UsersCompanion extends i0.UpdateCompanion<i1.User> {
  final i0.Value<int> id;
  final i0.Value<String> name;
  const UsersCompanion({
    this.id = const i0.Value.absent(),
    this.name = const i0.Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const i0.Value.absent(),
    required String name,
  }) : name = i0.Value(name);
  static i0.Insertable<i1.User> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? name,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  i2.UsersCompanion copyWith({i0.Value<int>? id, i0.Value<String>? name}) {
    return i2.UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = i0.Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class Friends extends i0.Table with i0.TableInfo<Friends, i2.Friend> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  Friends(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _userAMeta =
      const i0.VerificationMeta('userA');
  late final i0.GeneratedColumn<int> userA = i0.GeneratedColumn<int>(
      'user_a', aliasedName, false,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL REFERENCES users(id)');
  static const i0.VerificationMeta _userBMeta =
      const i0.VerificationMeta('userB');
  late final i0.GeneratedColumn<int> userB = i0.GeneratedColumn<int>(
      'user_b', aliasedName, false,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL REFERENCES users(id)');
  @override
  List<i0.GeneratedColumn> get $columns => [userA, userB];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'friends';
  @override
  i0.VerificationContext validateIntegrity(i0.Insertable<i2.Friend> instance,
      {bool isInserting = false}) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_a')) {
      context.handle(
          _userAMeta, userA.isAcceptableOrUnknown(data['user_a']!, _userAMeta));
    } else if (isInserting) {
      context.missing(_userAMeta);
    }
    if (data.containsKey('user_b')) {
      context.handle(
          _userBMeta, userB.isAcceptableOrUnknown(data['user_b']!, _userBMeta));
    } else if (isInserting) {
      context.missing(_userBMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {userA, userB};
  @override
  i2.Friend map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i2.Friend(
      userA: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}user_a'])!,
      userB: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}user_b'])!,
    );
  }

  @override
  Friends createAlias(String alias) {
    return Friends(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(user_a, user_b)'];
  @override
  bool get dontWriteConstraints => true;
}

class Friend extends i0.DataClass implements i0.Insertable<i2.Friend> {
  final int userA;
  final int userB;
  const Friend({required this.userA, required this.userB});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['user_a'] = i0.Variable<int>(userA);
    map['user_b'] = i0.Variable<int>(userB);
    return map;
  }

  i2.FriendsCompanion toCompanion(bool nullToAbsent) {
    return i2.FriendsCompanion(
      userA: i0.Value(userA),
      userB: i0.Value(userB),
    );
  }

  factory Friend.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return Friend(
      userA: serializer.fromJson<int>(json['user_a']),
      userB: serializer.fromJson<int>(json['user_b']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'user_a': serializer.toJson<int>(userA),
      'user_b': serializer.toJson<int>(userB),
    };
  }

  i2.Friend copyWith({int? userA, int? userB}) => i2.Friend(
        userA: userA ?? this.userA,
        userB: userB ?? this.userB,
      );
  @override
  String toString() {
    return (StringBuffer('Friend(')
          ..write('userA: $userA, ')
          ..write('userB: $userB')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userA, userB);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i2.Friend &&
          other.userA == this.userA &&
          other.userB == this.userB);
}

class FriendsCompanion extends i0.UpdateCompanion<i2.Friend> {
  final i0.Value<int> userA;
  final i0.Value<int> userB;
  final i0.Value<int> rowid;
  const FriendsCompanion({
    this.userA = const i0.Value.absent(),
    this.userB = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  FriendsCompanion.insert({
    required int userA,
    required int userB,
    this.rowid = const i0.Value.absent(),
  })  : userA = i0.Value(userA),
        userB = i0.Value(userB);
  static i0.Insertable<i2.Friend> custom({
    i0.Expression<int>? userA,
    i0.Expression<int>? userB,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (userA != null) 'user_a': userA,
      if (userB != null) 'user_b': userB,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i2.FriendsCompanion copyWith(
      {i0.Value<int>? userA, i0.Value<int>? userB, i0.Value<int>? rowid}) {
    return i2.FriendsCompanion(
      userA: userA ?? this.userA,
      userB: userB ?? this.userB,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (userA.present) {
      map['user_a'] = i0.Variable<int>(userA.value);
    }
    if (userB.present) {
      map['user_b'] = i0.Variable<int>(userB.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FriendsCompanion(')
          ..write('userA: $userA, ')
          ..write('userB: $userB, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FriendsFilterComposer
    extends i0.FilterComposer<i0.GeneratedDatabase, i2.Friends> {
  $FriendsFilterComposer(super.$db, super.$table, {super.$joinBuilder});
}

class $FriendsOrderingComposer
    extends i0.OrderingComposer<i0.GeneratedDatabase, i2.Friends> {
  $FriendsOrderingComposer(super.$db, super.$table, {super.$joinBuilder});
}

class $FriendsProcessedTableManager extends i0.ProcessedTableManager<
    i0.GeneratedDatabase,
    i2.Friends,
    i2.Friend,
    $FriendsFilterComposer,
    $FriendsOrderingComposer,
    $FriendsProcessedTableManager,
    $FriendsInsertCompanionBuilder,
    $FriendsUpdateCompanionBuilder> {
  const $FriendsProcessedTableManager(super.$state);
}

typedef $FriendsInsertCompanionBuilder = i2.FriendsCompanion Function({
  required int userA,
  required int userB,
  i0.Value<int> rowid,
});
typedef $FriendsUpdateCompanionBuilder = i2.FriendsCompanion Function({
  i0.Value<int> userA,
  i0.Value<int> userB,
  i0.Value<int> rowid,
});

class $FriendsTableManager extends i0.RootTableManager<
    i0.GeneratedDatabase,
    i2.Friends,
    i2.Friend,
    $FriendsFilterComposer,
    $FriendsOrderingComposer,
    $FriendsProcessedTableManager,
    $FriendsInsertCompanionBuilder,
    $FriendsUpdateCompanionBuilder> {
  $FriendsTableManager(i0.GeneratedDatabase db, i2.Friends table)
      : super(i0.TableManagerState(
            db: db,
            table: table,
            filteringComposer: $FriendsFilterComposer(db, table),
            orderingComposer: $FriendsOrderingComposer(db, table),
            getChildManagerBuilder: (p0) => $FriendsProcessedTableManager(p0),
            getUpdateCompanionBuilder: ({
              i0.Value<int> userA = const i0.Value.absent(),
              i0.Value<int> userB = const i0.Value.absent(),
              i0.Value<int> rowid = const i0.Value.absent(),
            }) =>
                i2.FriendsCompanion(
                  userA: userA,
                  userB: userB,
                  rowid: rowid,
                ),
            getInsertCompanionBuilder: ({
              required int userA,
              required int userB,
              i0.Value<int> rowid = const i0.Value.absent(),
            }) =>
                i2.FriendsCompanion.insert(
                  userA: userA,
                  userB: userB,
                  rowid: rowid,
                )));
}

class WithExistingDrift extends i3.ModularAccessor {
  WithExistingDrift(i0.GeneratedDatabase db) : super(db);
  i0.Selectable<i1.UserWithFriends> allFriendsOf(int id) {
    return customSelect(
        'SELECT"users"."id" AS "nested_0.id", "users"."name" AS "nested_0.name", users.id AS "\$n_0", users.id AS "\$n_1" FROM users WHERE id = ?1',
        variables: [
          i0.Variable<int>(id)
        ],
        readsFrom: {
          users,
          friends,
        }).asyncMap((i0.QueryRow row) async => i1.UserWithFriends(
          await users.mapFromRow(row, tablePrefix: 'nested_0'),
          friends: await customSelect(
                  'SELECT * FROM users AS a INNER JOIN friends ON user_a = a.id WHERE user_b = ?1 OR user_a = ?2',
                  variables: [
                i0.Variable<int>(row.read('\$n_0')),
                i0.Variable<int>(row.read('\$n_1'))
              ],
                  readsFrom: {
                users,
                friends,
              })
              .map((i0.QueryRow row) => i1.User(
                    row.read<int>('id'),
                    row.read<String>('name'),
                  ))
              .get(),
        ));
  }

  i2.Users get users => this.resultSet<i2.Users>('users');
  i2.Friends get friends => this.resultSet<i2.Friends>('friends');
}
