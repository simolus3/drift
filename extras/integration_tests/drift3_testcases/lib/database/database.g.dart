// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users
    with ResultSet<User, $UsersTable>
    implements GeneratedTable<User, $UsersTable> {
  @override
  final String? alias;
  $UsersTable([this.alias]);
  @override
  late final TableColumn<int> id = TableColumn<int>(
      name: 'id',
      sqlType: SqlType.int,
      requiredDuringInsert: false,
      constraints: () => [
            const ColumnPrimaryKeyConstraint(isAutoIncrementing: true),
            const ColumnNotNullConstraint()
          ])
    ..owningResultSet = this;
  @override
  late final TableColumn<String> name = TableColumn<String>(
      name: 'name',
      sqlType: SqlType.text,
      requiredDuringInsert: true,
      constraints: () => [const ColumnNotNullConstraint()])
    ..owningResultSet = this;
  @override
  late final TableColumn<DateTime> birthDate = TableColumn<DateTime>(
      name: 'birth_date',
      sqlType: SqlType.dateTime,
      requiredDuringInsert: true,
      constraints: () => [const ColumnNotNullConstraint()])
    ..owningResultSet = this;
  @override
  late final TableColumn<Uint8List> profilePicture = TableColumn<Uint8List>(
      name: 'profile_picture',
      sqlType: SqlType.byteArray,
      requiredDuringInsert: false)
    ..owningResultSet = this;
  @override
  late final TableColumnWithTypeConverter<Preferences?, String> preferences =
      TableColumn<String>(
              name: 'preferences',
              sqlType: SqlType.text,
              requiredDuringInsert: false)
          .withConverter<Preferences?>($UsersTable.$converterpreferences)
        ..owningResultSet = this;
  @override
  List<TableColumn> get columns =>
      [id, name, birthDate, profilePicture, preferences];
  @override
  String get entityName => $name;
  static const String $name = 'users';
  @override
  $UsersTable asSelfType() => this;

  @override
  User? Function(RawRow) createMapperFromPositions(
      DriftDialect dialect, List<ColumnPosition> positions) {
    final pos$id = positions[0].index;
    final type$0 = SqlType.int.resolveIn(dialect);
    final pos$name = positions[1].index;
    final type$1 = SqlType.text.resolveIn(dialect);
    final pos$birthDate = positions[2].index;
    final type$2 = SqlType.dateTime.resolveIn(dialect);
    final pos$profilePicture = positions[3].index;
    final type$3 = SqlType.byteArray.resolveIn(dialect);
    final pos$preferences = positions[4].index;
    return (RawRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row[pos$id] == null) {
        return null;
      }
      return User(
        id: type$0.dartValue(row[pos$id]!),
        name: type$1.dartValue(row[pos$name]!),
        birthDate: type$2.dartValue(row[pos$birthDate]!),
        profilePicture: type$3.nullableDartValue(row[pos$profilePicture]),
        preferences: $UsersTable.$converterpreferences
            .fromSql(type$1.nullableDartValue(row[pos$preferences])),
      );
    };
  }

  @override
  $UsersTable withAlias(String alias) {
    return $UsersTable(alias);
  }

  static TypeConverter<Preferences?, String?> $converterpreferences =
      const PreferenceConverter();
}

class User extends LegacyDataClass implements Insertable<User> {
  /// The user id
  final int id;
  final String name;

  /// The users birth date
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
    map['id'] = Variable<int>(id, SqlType.int);
    map['name'] = Variable<String>(name, SqlType.text);
    map['birth_date'] = Variable<DateTime>(birthDate, SqlType.dateTime);
    if (!nullToAbsent || profilePicture != null) {
      map['profile_picture'] =
          Variable<Uint8List>(profilePicture, SqlType.byteArray);
    }
    if (!nullToAbsent || preferences != null) {
      map['preferences'] = Variable<String>(
          $UsersTable.$converterpreferences.toSql(preferences), SqlType.text);
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
      birthDate: serializer.fromJson<DateTime>(json['birthDate']),
      profilePicture: serializer.fromJson<Uint8List?>(json['profilePicture']),
      preferences: serializer.fromJson<Preferences?>(json['preferences']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'birthDate': serializer.toJson<DateTime>(birthDate),
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
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      profilePicture: data.profilePicture.present
          ? data.profilePicture.value
          : this.profilePicture,
      preferences:
          data.preferences.present ? data.preferences.value : this.preferences,
    );
  }

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
      map['id'] = Variable<int>(id.value, SqlType.int);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value, SqlType.text);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<DateTime>(birthDate.value, SqlType.dateTime);
    }
    if (profilePicture.present) {
      map['profile_picture'] =
          Variable<Uint8List>(profilePicture.value, SqlType.byteArray);
    }
    if (preferences.present) {
      map['preferences'] = Variable<String>(
          $UsersTable.$converterpreferences.toSql(preferences.value),
          SqlType.text);
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
    with ResultSet<Friendship, $FriendshipsTable>
    implements GeneratedTable<Friendship, $FriendshipsTable> {
  @override
  final String? alias;
  $FriendshipsTable([this.alias]);
  @override
  late final TableColumn<int> firstUser = TableColumn<int>(
      name: 'first_user',
      sqlType: SqlType.int,
      requiredDuringInsert: true,
      constraints: () => [const ColumnNotNullConstraint()])
    ..owningResultSet = this;
  @override
  late final TableColumn<int> secondUser = TableColumn<int>(
      name: 'second_user',
      sqlType: SqlType.int,
      requiredDuringInsert: true,
      constraints: () => [const ColumnNotNullConstraint()])
    ..owningResultSet = this;
  @override
  late final TableColumn<bool> reallyGoodFriends = TableColumn<bool>(
      name: 'really_good_friends',
      sqlType: SqlType.bool,
      requiredDuringInsert: false,
      constraints: () => [
            const ColumnNotNullConstraint(),
            ColumnDefaultConstraint<bool>(const Literal(false))
          ])
    ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [firstUser, secondUser, reallyGoodFriends];
  @override
  String get entityName => $name;
  static const String $name = 'friendships';
  @override
  $FriendshipsTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {firstUser, secondUser};
  @override
  Friendship? Function(RawRow) createMapperFromPositions(
      DriftDialect dialect, List<ColumnPosition> positions) {
    final pos$firstUser = positions[0].index;
    final type$0 = SqlType.int.resolveIn(dialect);
    final pos$secondUser = positions[1].index;
    final pos$reallyGoodFriends = positions[2].index;
    final type$1 = SqlType.bool.resolveIn(dialect);
    return (RawRow row) {
      // Not part of row if non-nullable column "firstUser" is missing
      if (row[pos$firstUser] == null) {
        return null;
      }
      return Friendship(
        firstUser: type$0.dartValue(row[pos$firstUser]!),
        secondUser: type$0.dartValue(row[pos$secondUser]!),
        reallyGoodFriends: type$1.dartValue(row[pos$reallyGoodFriends]!),
      );
    };
  }

  @override
  $FriendshipsTable withAlias(String alias) {
    return $FriendshipsTable(alias);
  }
}

class Friendship extends LegacyDataClass implements Insertable<Friendship> {
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
    map['first_user'] = Variable<int>(firstUser, SqlType.int);
    map['second_user'] = Variable<int>(secondUser, SqlType.int);
    map['really_good_friends'] =
        Variable<bool>(reallyGoodFriends, SqlType.bool);
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
  Friendship copyWithCompanion(FriendshipsCompanion data) {
    return Friendship(
      firstUser: data.firstUser.present ? data.firstUser.value : this.firstUser,
      secondUser:
          data.secondUser.present ? data.secondUser.value : this.secondUser,
      reallyGoodFriends: data.reallyGoodFriends.present
          ? data.reallyGoodFriends.value
          : this.reallyGoodFriends,
    );
  }

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
      map['first_user'] = Variable<int>(firstUser.value, SqlType.int);
    }
    if (secondUser.present) {
      map['second_user'] = Variable<int>(secondUser.value, SqlType.int);
    }
    if (reallyGoodFriends.present) {
      map['really_good_friends'] =
          Variable<bool>(reallyGoodFriends.value, SqlType.bool);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value, SqlType.int);
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

abstract base class _$Database extends GeneratedDatabase {
  _$Database(super.implementation);
  $UsersTable get users => $UsersTable();
  $FriendshipsTable get friendships => $FriendshipsTable();
  TableOrViewStatements<User, $UsersTable> get usersQueries =>
      this.users.statements(this);
  TableOrViewStatements<Friendship, $FriendshipsTable> get friendshipsQueries =>
      this.friendships.statements(this);
  @override
  Map<KnownSqlDialect, Object> get dialectOptions => {
        KnownSqlDialect.sqlite: const SqliteOptions(
          strictTablesByDefault: false,
          storeDateTimesAsText: false,
          useBinaryJsonRepresentation: false,
        ),
      };
  Selectable<User> mostPopularUsers(int amount) {
    return customSelectMapped<User>(
        query: switch (dialect.known) {
          KnownSqlDialect.sqlite =>
            'SELECT u.id, u.name, u.birth_date, u.profile_picture, u.preferences FROM users AS u ORDER BY (SELECT COUNT(*) FROM friendships WHERE first_user = u.id OR second_user = u.id) DESC LIMIT ?1',
          KnownSqlDialect.postgres =>
            'SELECT u.id, u.name, u.birth_date, u.profile_picture, u.preferences FROM users AS u ORDER BY (SELECT COUNT(*) FROM friendships WHERE first_user = u.id OR second_user = u.id) DESC LIMIT \$1',
          KnownSqlDialect.mariadb ||
          _ =>
            'SELECT u.id, u.name, u.birth_date, u.profile_picture, u.preferences FROM users AS u ORDER BY (SELECT COUNT(*) FROM friendships WHERE first_user = u.id OR second_user = u.id) DESC LIMIT ?',
        },
        variables: [Variable<int>(amount, SqlType.int)],
        readsFrom: {
          $UsersTable(),
          $FriendshipsTable(),
        },
        createMapper: (RawResultSet _) {
          final map_0 = $UsersTable().createMapperFromPositions(dialect, const [
            ColumnPosition(0),
            ColumnPosition(1),
            ColumnPosition(2),
            ColumnPosition(3),
            ColumnPosition(4),
          ]);

          return (RawRow row) => map_0(row)!;
        });
  }

  Selectable<int> amountOfGoodFriends(int user) {
    return customSelectMapped<int>(
        query: switch (dialect.known) {
          KnownSqlDialect.sqlite =>
            'SELECT COUNT(*) FROM friendships AS f WHERE f.really_good_friends = TRUE AND(f.first_user = ?1 OR f.second_user = ?1)',
          KnownSqlDialect.postgres =>
            'SELECT COUNT(*) FROM friendships AS f WHERE f.really_good_friends = TRUE AND(f.first_user = \$1 OR f.second_user = \$1)',
          KnownSqlDialect.mariadb ||
          _ =>
            'SELECT COUNT(*) FROM friendships AS f WHERE f.really_good_friends = TRUE AND(f.first_user = ? OR f.second_user = ?)',
        },
        variables: dialect.desugarDuplicateVariables([
          Variable<int>(user, SqlType.int)
        ], [
          1,
          1,
        ]),
        readsFrom: {
          $FriendshipsTable(),
        },
        createMapper: (RawResultSet _) {
          final type$0 = SqlType.int.resolveIn(dialect);

          return (RawRow row) => type$0.dartValue(row[0]!);
        });
  }

  Selectable<FriendshipsOfResult> friendshipsOf(int user) {
    return customSelectMapped<FriendshipsOfResult>(
        query: switch (dialect.known) {
          KnownSqlDialect.sqlite =>
            'SELECT f.really_good_friends,"user"."id", "user"."name", "user"."birth_date", "user"."profile_picture", "user"."preferences" FROM friendships AS f INNER JOIN users AS user ON user.id IN (f.first_user, f.second_user) AND user.id != ?1 WHERE(f.first_user = ?1 OR f.second_user = ?1)',
          KnownSqlDialect.postgres =>
            'SELECT f.really_good_friends,"user"."id", "user"."name", "user"."birth_date", "user"."profile_picture", "user"."preferences" FROM friendships AS f INNER JOIN users AS "user" ON "user".id IN (f.first_user, f.second_user) AND "user".id != \$1 WHERE(f.first_user = \$1 OR f.second_user = \$1)',
          KnownSqlDialect.mariadb ||
          _ =>
            'SELECT f.really_good_friends,`user`.`id`, `user`.`name`, `user`.`birth_date`, `user`.`profile_picture`, `user`.`preferences` FROM friendships AS f INNER JOIN users AS user ON user.id IN (f.first_user, f.second_user) AND user.id != ? WHERE(f.first_user = ? OR f.second_user = ?)',
        },
        variables: dialect.desugarDuplicateVariables([
          Variable<int>(user, SqlType.int)
        ], [
          1,
          1,
          1,
        ]),
        readsFrom: {
          $FriendshipsTable(),
          $UsersTable(),
        },
        createMapper: (RawResultSet _) {
          final type$0 = SqlType.bool.resolveIn(dialect);
          final map_0 = $UsersTable().createMapperFromPositions(dialect, const [
            ColumnPosition(1),
            ColumnPosition(2),
            ColumnPosition(3),
            ColumnPosition(4),
            ColumnPosition(5),
          ]);

          return (RawRow row) => FriendshipsOfResult(
                reallyGoodFriends: type$0.dartValue(row[0]!),
                user: map_0(row)!,
              );
        });
  }

  Selectable<int> userCount() {
    return customSelectMapped<int>(
        query: 'SELECT COUNT(id) FROM users',
        variables: [],
        readsFrom: {
          $UsersTable(),
        },
        createMapper: (RawResultSet _) {
          final type$0 = SqlType.int.resolveIn(dialect);

          return (RawRow row) => type$0.dartValue(row[0]!);
        });
  }

  Selectable<Preferences?> settingsFor(int user) {
    return customSelectMapped<Preferences?>(
        query: switch (dialect.known) {
          KnownSqlDialect.sqlite =>
            'SELECT preferences FROM users WHERE id = ?1',
          KnownSqlDialect.postgres =>
            'SELECT preferences FROM users WHERE id = \$1',
          KnownSqlDialect.mariadb ||
          _ =>
            'SELECT preferences FROM users WHERE id = ?',
        },
        variables: [Variable<int>(user, SqlType.int)],
        readsFrom: {
          $UsersTable(),
        },
        createMapper: (RawResultSet _) {
          final type$0 = SqlType.text.resolveIn(dialect);

          return (RawRow row) => $UsersTable.$converterpreferences
              .fromSql(type$0.nullableDartValue(row[0]));
        });
  }

  Selectable<User> usersById(List<int> var1) {
    var $arrayStartIndex = 0;
    final expandedvar1 = $expandVar($arrayStartIndex, var1.length);
    $arrayStartIndex += var1.length;
    return customSelectMapped<User>(
        query: switch (dialect.known) {
          KnownSqlDialect.sqlite ||
          KnownSqlDialect.postgres =>
            'SELECT "_s:0".id, "_s:0".name, "_s:0".birth_date, "_s:0".profile_picture, "_s:0".preferences FROM users AS "_s:0" WHERE "_s:0".id IN ($expandedvar1)',
          KnownSqlDialect.mariadb ||
          _ =>
            'SELECT `_s:0`.id, `_s:0`.name, `_s:0`.birth_date, `_s:0`.profile_picture, `_s:0`.preferences FROM users AS `_s:0` WHERE `_s:0`.id IN ($expandedvar1)',
        },
        variables: [for (var $ in var1) Variable<int>($, SqlType.int)],
        readsFrom: {
          $UsersTable(),
        },
        createMapper: (RawResultSet _) {
          final map_0 = $UsersTable().createMapperFromPositions(dialect, const [
            ColumnPosition(0),
            ColumnPosition(1),
            ColumnPosition(2),
            ColumnPosition(3),
            ColumnPosition(4),
          ]);

          return (RawRow row) => map_0(row)!;
        });
  }

  Future<List<Friendship>> returning(int var1, int var2, bool var3) {
    return customWriteReturning(
        switch (dialect.known) {
          KnownSqlDialect.sqlite =>
            'INSERT INTO friendships VALUES (?1, ?2, ?3) RETURNING *',
          KnownSqlDialect.postgres =>
            'INSERT INTO friendships VALUES (\$1, \$2, \$3) RETURNING *',
          KnownSqlDialect.mariadb ||
          _ =>
            'INSERT INTO friendships VALUES (?, ?, ?) RETURNING *',
        },
        variables: [
          Variable<int>(var1, SqlType.int),
          Variable<int>(var2, SqlType.int),
          Variable<bool>(var3, SqlType.bool)
        ],
        updates: {
          $FriendshipsTable()
        }).then((rows) {
      final map_0 =
          $FriendshipsTable().createMapperFromPositions(dialect, const [
        ColumnPosition(0),
        ColumnPosition(1),
        ColumnPosition(2),
      ]);

      return rows.map((row) => map_0(row)!).toList();
    });
  }

  @override
  DatabaseSchema get schema => _$schema;
  static final DatabaseSchema _$schema = DatabaseSchema([
    $UsersTable(),
    $FriendshipsTable(),
  ]);
}

final class FriendshipsOfResult {
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
