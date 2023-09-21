// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id =
      GeneratedColumn<int>('id', aliasedName, false,
          hasAutoIncrement: true,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintsDependsOnDialect({
            SqlDialect.sqlite: 'PRIMARY KEY AUTOINCREMENT',
            SqlDialect.postgres: 'PRIMARY KEY AUTOINCREMENT',
            SqlDialect.mariadb: 'PRIMARY KEY AUTO_INCREMENT',
          }));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _birthDateMeta =
      const VerificationMeta('birthDate');
  @override
  late final GeneratedColumn<DateTime> birthDate = GeneratedColumn<DateTime>(
      'birth_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _profilePictureMeta =
      const VerificationMeta('profilePicture');
  @override
  late final GeneratedColumn<Uint8List> profilePicture =
      GeneratedColumn<Uint8List>('profile_picture', aliasedName, true,
          type: DriftSqlType.blob, requiredDuringInsert: false);
  static const VerificationMeta _preferencesMeta =
      const VerificationMeta('preferences');
  @override
  late final GeneratedColumnWithTypeConverter<Preferences?, String>
      preferences = GeneratedColumn<String>('preferences', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<Preferences?>($UsersTable.$converterpreferences);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, birthDate, profilePicture, preferences];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
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
    if (data.containsKey('birth_date')) {
      context.handle(_birthDateMeta,
          birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta));
    } else if (isInserting) {
      context.missing(_birthDateMeta);
    }
    if (data.containsKey('profile_picture')) {
      context.handle(
          _profilePictureMeta,
          profilePicture.isAcceptableOrUnknown(
              data['profile_picture']!, _profilePictureMeta));
    }
    context.handle(_preferencesMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      birthDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}birth_date'])!,
      profilePicture: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}profile_picture']),
      preferences: $UsersTable.$converterpreferences.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}preferences'])),
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }

  static TypeConverter<Preferences?, String?> $converterpreferences =
      const PreferenceConverter();
}

class User extends DataClass implements Insertable<User> {
  /// The user id
  final int id;
  final String name;

  /// The users birth date
  ///
  /// Mapped from json `born_on`
  final DateTime birthDate;
  final Uint8List? profilePicture;
  final Preferences? preferences;
  const User(
      {required this.id,
      required this.name,
      required this.birthDate,
      this.profilePicture,
      this.preferences});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['birth_date'] = Variable<DateTime>(birthDate);
    if (!nullToAbsent || profilePicture != null) {
      map['profile_picture'] = Variable<Uint8List>(profilePicture);
    }
    if (!nullToAbsent || preferences != null) {
      final converter = $UsersTable.$converterpreferences;
      map['preferences'] = Variable<String>(converter.toSql(preferences));
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      birthDate: Value(birthDate),
      profilePicture: profilePicture == null && nullToAbsent
          ? const Value.absent()
          : Value(profilePicture),
      preferences: preferences == null && nullToAbsent
          ? const Value.absent()
          : Value(preferences),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      birthDate: serializer.fromJson<DateTime>(json['born_on']),
      profilePicture: serializer.fromJson<Uint8List?>(json['profilePicture']),
      preferences: serializer.fromJson<Preferences?>(json['preferences']),
    );
  }
  factory User.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      User.fromJson(DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'born_on': serializer.toJson<DateTime>(birthDate),
      'profilePicture': serializer.toJson<Uint8List?>(profilePicture),
      'preferences': serializer.toJson<Preferences?>(preferences),
    };
  }

  User copyWith(
          {int? id,
          String? name,
          DateTime? birthDate,
          Value<Uint8List?> profilePicture = const Value.absent(),
          Value<Preferences?> preferences = const Value.absent()}) =>
      User(
        id: id ?? this.id,
        name: name ?? this.name,
        birthDate: birthDate ?? this.birthDate,
        profilePicture:
            profilePicture.present ? profilePicture.value : this.profilePicture,
        preferences: preferences.present ? preferences.value : this.preferences,
      );
  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('birthDate: $birthDate, ')
          ..write('profilePicture: $profilePicture, ')
          ..write('preferences: $preferences')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, birthDate,
      $driftBlobEquality.hash(profilePicture), preferences);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.name == this.name &&
          other.birthDate == this.birthDate &&
          $driftBlobEquality.equals(
              other.profilePicture, this.profilePicture) &&
          other.preferences == this.preferences);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> birthDate;
  final Value<Uint8List?> profilePicture;
  final Value<Preferences?> preferences;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.profilePicture = const Value.absent(),
    this.preferences = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required DateTime birthDate,
    this.profilePicture = const Value.absent(),
    this.preferences = const Value.absent(),
  })  : name = Value(name),
        birthDate = Value(birthDate);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? birthDate,
    Expression<Uint8List>? profilePicture,
    Expression<String>? preferences,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (birthDate != null) 'birth_date': birthDate,
      if (profilePicture != null) 'profile_picture': profilePicture,
      if (preferences != null) 'preferences': preferences,
    });
  }

  UsersCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<DateTime>? birthDate,
      Value<Uint8List?>? profilePicture,
      Value<Preferences?>? preferences}) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      profilePicture: profilePicture ?? this.profilePicture,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<DateTime>(birthDate.value);
    }
    if (profilePicture.present) {
      map['profile_picture'] = Variable<Uint8List>(profilePicture.value);
    }
    if (preferences.present) {
      final converter = $UsersTable.$converterpreferences;
      map['preferences'] = Variable<String>(converter.toSql(preferences.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('birthDate: $birthDate, ')
          ..write('profilePicture: $profilePicture, ')
          ..write('preferences: $preferences')
          ..write(')'))
        .toString();
  }
}

class $FriendshipsTable extends Friendships
    with TableInfo<$FriendshipsTable, Friendship> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FriendshipsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _firstUserMeta =
      const VerificationMeta('firstUser');
  @override
  late final GeneratedColumn<int> firstUser = GeneratedColumn<int>(
      'first_user', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _secondUserMeta =
      const VerificationMeta('secondUser');
  @override
  late final GeneratedColumn<int> secondUser = GeneratedColumn<int>(
      'second_user', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _reallyGoodFriendsMeta =
      const VerificationMeta('reallyGoodFriends');
  @override
  late final GeneratedColumn<bool> reallyGoodFriends =
      GeneratedColumn<bool>('really_good_friends', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintsDependsOnDialect({
            SqlDialect.sqlite: 'CHECK ("really_good_friends" IN (0, 1))',
            SqlDialect.postgres: '',
            SqlDialect.mariadb: 'CHECK (`really_good_friends` IN (0, 1))',
          }),
          defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [firstUser, secondUser, reallyGoodFriends];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'friendships';
  @override
  VerificationContext validateIntegrity(Insertable<Friendship> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('first_user')) {
      context.handle(_firstUserMeta,
          firstUser.isAcceptableOrUnknown(data['first_user']!, _firstUserMeta));
    } else if (isInserting) {
      context.missing(_firstUserMeta);
    }
    if (data.containsKey('second_user')) {
      context.handle(
          _secondUserMeta,
          secondUser.isAcceptableOrUnknown(
              data['second_user']!, _secondUserMeta));
    } else if (isInserting) {
      context.missing(_secondUserMeta);
    }
    if (data.containsKey('really_good_friends')) {
      context.handle(
          _reallyGoodFriendsMeta,
          reallyGoodFriends.isAcceptableOrUnknown(
              data['really_good_friends']!, _reallyGoodFriendsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {firstUser, secondUser};
  @override
  Friendship map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Friendship(
      firstUser: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}first_user'])!,
      secondUser: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}second_user'])!,
      reallyGoodFriends: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}really_good_friends'])!,
    );
  }

  @override
  $FriendshipsTable createAlias(String alias) {
    return $FriendshipsTable(attachedDatabase, alias);
  }
}

class Friendship extends DataClass implements Insertable<Friendship> {
  final int firstUser;
  final int secondUser;
  final bool reallyGoodFriends;
  const Friendship(
      {required this.firstUser,
      required this.secondUser,
      required this.reallyGoodFriends});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['first_user'] = Variable<int>(firstUser);
    map['second_user'] = Variable<int>(secondUser);
    map['really_good_friends'] = Variable<bool>(reallyGoodFriends);
    return map;
  }

  FriendshipsCompanion toCompanion(bool nullToAbsent) {
    return FriendshipsCompanion(
      firstUser: Value(firstUser),
      secondUser: Value(secondUser),
      reallyGoodFriends: Value(reallyGoodFriends),
    );
  }

  factory Friendship.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Friendship(
      firstUser: serializer.fromJson<int>(json['firstUser']),
      secondUser: serializer.fromJson<int>(json['secondUser']),
      reallyGoodFriends: serializer.fromJson<bool>(json['reallyGoodFriends']),
    );
  }
  factory Friendship.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      Friendship.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'firstUser': serializer.toJson<int>(firstUser),
      'secondUser': serializer.toJson<int>(secondUser),
      'reallyGoodFriends': serializer.toJson<bool>(reallyGoodFriends),
    };
  }

  Friendship copyWith(
          {int? firstUser, int? secondUser, bool? reallyGoodFriends}) =>
      Friendship(
        firstUser: firstUser ?? this.firstUser,
        secondUser: secondUser ?? this.secondUser,
        reallyGoodFriends: reallyGoodFriends ?? this.reallyGoodFriends,
      );
  @override
  String toString() {
    return (StringBuffer('Friendship(')
          ..write('firstUser: $firstUser, ')
          ..write('secondUser: $secondUser, ')
          ..write('reallyGoodFriends: $reallyGoodFriends')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(firstUser, secondUser, reallyGoodFriends);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Friendship &&
          other.firstUser == this.firstUser &&
          other.secondUser == this.secondUser &&
          other.reallyGoodFriends == this.reallyGoodFriends);
}

class FriendshipsCompanion extends UpdateCompanion<Friendship> {
  final Value<int> firstUser;
  final Value<int> secondUser;
  final Value<bool> reallyGoodFriends;
  final Value<int> rowid;
  const FriendshipsCompanion({
    this.firstUser = const Value.absent(),
    this.secondUser = const Value.absent(),
    this.reallyGoodFriends = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FriendshipsCompanion.insert({
    required int firstUser,
    required int secondUser,
    this.reallyGoodFriends = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : firstUser = Value(firstUser),
        secondUser = Value(secondUser);
  static Insertable<Friendship> custom({
    Expression<int>? firstUser,
    Expression<int>? secondUser,
    Expression<bool>? reallyGoodFriends,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (firstUser != null) 'first_user': firstUser,
      if (secondUser != null) 'second_user': secondUser,
      if (reallyGoodFriends != null) 'really_good_friends': reallyGoodFriends,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FriendshipsCompanion copyWith(
      {Value<int>? firstUser,
      Value<int>? secondUser,
      Value<bool>? reallyGoodFriends,
      Value<int>? rowid}) {
    return FriendshipsCompanion(
      firstUser: firstUser ?? this.firstUser,
      secondUser: secondUser ?? this.secondUser,
      reallyGoodFriends: reallyGoodFriends ?? this.reallyGoodFriends,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (firstUser.present) {
      map['first_user'] = Variable<int>(firstUser.value);
    }
    if (secondUser.present) {
      map['second_user'] = Variable<int>(secondUser.value);
    }
    if (reallyGoodFriends.present) {
      map['really_good_friends'] = Variable<bool>(reallyGoodFriends.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FriendshipsCompanion(')
          ..write('firstUser: $firstUser, ')
          ..write('secondUser: $secondUser, ')
          ..write('reallyGoodFriends: $reallyGoodFriends, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(e);
  late final $UsersTable users = $UsersTable(this);
  late final $FriendshipsTable friendships = $FriendshipsTable(this);
  Selectable<User> mostPopularUsers(int amount) {
    return customSelect(
        switch (executor.dialect) {
          SqlDialect.sqlite =>
            'SELECT * FROM users AS u ORDER BY (SELECT COUNT(*) FROM friendships WHERE first_user = u.id OR second_user = u.id) DESC LIMIT ?1',
          SqlDialect.postgres =>
            'SELECT * FROM users AS u ORDER BY (SELECT COUNT(*) FROM friendships WHERE first_user = u.id OR second_user = u.id) DESC LIMIT \$1',
          SqlDialect.mariadb ||
          _ =>
            'SELECT * FROM users AS u ORDER BY (SELECT COUNT(*) FROM friendships WHERE first_user = u.id OR second_user = u.id) DESC LIMIT ?',
        },
        variables: [
          Variable<int>(amount)
        ],
        readsFrom: {
          users,
          friendships,
        }).asyncMap(users.mapFromRow);
  }

  Selectable<int> amountOfGoodFriends(int user) {
    return customSelect(
        switch (executor.dialect) {
          SqlDialect.sqlite =>
            'SELECT COUNT(*) AS _c0 FROM friendships AS f WHERE f.really_good_friends = TRUE AND(f.first_user = ?1 OR f.second_user = ?1)',
          SqlDialect.postgres =>
            'SELECT COUNT(*) AS _c0 FROM friendships AS f WHERE f.really_good_friends = TRUE AND(f.first_user = \$1 OR f.second_user = \$1)',
          SqlDialect.mariadb ||
          _ =>
            'SELECT COUNT(*) AS _c0 FROM friendships AS f WHERE f.really_good_friends = TRUE AND(f.first_user = ? OR f.second_user = ?)',
        },
        variables: executor.dialect.desugarDuplicateVariables([
          Variable<int>(user)
        ], [
          1,
          1,
        ]),
        readsFrom: {
          friendships,
        }).map((QueryRow row) => row.read<int>('_c0'));
  }

  Selectable<FriendshipsOfResult> friendshipsOf(int user) {
    return customSelect(
        switch (executor.dialect) {
          SqlDialect.sqlite =>
            'SELECT f.really_good_friends,"user"."id" AS "nested_0.id", "user"."name" AS "nested_0.name", "user"."birth_date" AS "nested_0.birth_date", "user"."profile_picture" AS "nested_0.profile_picture", "user"."preferences" AS "nested_0.preferences" FROM friendships AS f INNER JOIN users AS user ON user.id IN (f.first_user, f.second_user) AND user.id != ?1 WHERE(f.first_user = ?1 OR f.second_user = ?1)',
          SqlDialect.postgres =>
            'SELECT f.really_good_friends,"user"."id" AS "nested_0.id", "user"."name" AS "nested_0.name", "user"."birth_date" AS "nested_0.birth_date", "user"."profile_picture" AS "nested_0.profile_picture", "user"."preferences" AS "nested_0.preferences" FROM friendships AS f INNER JOIN users AS "user" ON "user".id IN (f.first_user, f.second_user) AND "user".id != \$1 WHERE(f.first_user = \$1 OR f.second_user = \$1)',
          SqlDialect.mariadb ||
          _ =>
            'SELECT f.really_good_friends,`user`.`id` AS `nested_0.id`, `user`.`name` AS `nested_0.name`, `user`.`birth_date` AS `nested_0.birth_date`, `user`.`profile_picture` AS `nested_0.profile_picture`, `user`.`preferences` AS `nested_0.preferences` FROM friendships AS f INNER JOIN users AS user ON user.id IN (f.first_user, f.second_user) AND user.id != ? WHERE(f.first_user = ? OR f.second_user = ?)',
        },
        variables: executor.dialect.desugarDuplicateVariables([
          Variable<int>(user)
        ], [
          1,
          1,
          1,
        ]),
        readsFrom: {
          friendships,
          users,
        }).asyncMap((QueryRow row) async => FriendshipsOfResult(
          reallyGoodFriends: row.read<bool>('really_good_friends'),
          user: await users.mapFromRow(row, tablePrefix: 'nested_0'),
        ));
  }

  Selectable<int> userCount() {
    return customSelect('SELECT COUNT(id) AS _c0 FROM users',
        variables: [],
        readsFrom: {
          users,
        }).map((QueryRow row) => row.read<int>('_c0'));
  }

  Selectable<Preferences?> settingsFor(int user) {
    return customSelect(
        switch (executor.dialect) {
          SqlDialect.sqlite => 'SELECT preferences FROM users WHERE id = ?1',
          SqlDialect.postgres => 'SELECT preferences FROM users WHERE id = \$1',
          SqlDialect.mariadb ||
          _ =>
            'SELECT preferences FROM users WHERE id = ?',
        },
        variables: [
          Variable<int>(user)
        ],
        readsFrom: {
          users,
        }).map((QueryRow row) => $UsersTable.$converterpreferences
        .fromSql(row.readNullable<String>('preferences')));
  }

  Selectable<User> usersById(List<int> var1) {
    var $arrayStartIndex = 1;
    final expandedvar1 = $expandVar($arrayStartIndex, var1.length);
    $arrayStartIndex += var1.length;
    return customSelect('SELECT * FROM users WHERE id IN ($expandedvar1)',
        variables: [
          for (var $ in var1) Variable<int>($)
        ],
        readsFrom: {
          users,
        }).asyncMap(users.mapFromRow);
  }

  Future<List<Friendship>> returning(int var1, int var2, bool var3) {
    return customWriteReturning(
        switch (executor.dialect) {
          SqlDialect.sqlite =>
            'INSERT INTO friendships VALUES (?1, ?2, ?3) RETURNING *',
          SqlDialect.postgres =>
            'INSERT INTO friendships VALUES (\$1, \$2, \$3) RETURNING *',
          SqlDialect.mariadb ||
          _ =>
            'INSERT INTO friendships VALUES (?, ?, ?) RETURNING *',
        },
        variables: [
          Variable<int>(var1),
          Variable<int>(var2),
          Variable<bool>(var3)
        ],
        updates: {
          friendships
        }).then((rows) => Future.wait(rows.map(friendships.mapFromRow)));
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [users, friendships];
}

class FriendshipsOfResult {
  final bool reallyGoodFriends;
  final User user;
  FriendshipsOfResult({
    required this.reallyGoodFriends,
    required this.user,
  });
  @override
  int get hashCode => Object.hash(reallyGoodFriends, user);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FriendshipsOfResult &&
          other.reallyGoodFriends == this.reallyGoodFriends &&
          other.user == this.user);
  @override
  String toString() {
    return (StringBuffer('FriendshipsOfResult(')
          ..write('reallyGoodFriends: $reallyGoodFriends, ')
          ..write('user: $user')
          ..write(')'))
        .toString();
  }
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Preferences _$PreferencesFromJson(Map<String, dynamic> json) => Preferences(
      json['receiveEmails'] as bool,
    );

Map<String, dynamic> _$PreferencesToJson(Preferences instance) =>
    <String, dynamic>{
      'receiveEmails': instance.receiveEmails,
    };
