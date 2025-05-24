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
      type: BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: false,
      constraints: () =>
          [const ColumnPrimaryKeyConstraint(isAutoIncrementing: true)])
    ..owningResultSet = this;
  @override
  late final TableColumn<String> name = TableColumn<String>(
      name: 'name',
      type: BuiltinDriftType.text,
      isNullable: false,
      requiredDuringInsert: true)
    ..owningResultSet = this;
  @override
  late final TableColumn<DateTime> birthDate = TableColumn<DateTime>(
      name: 'birth_date',
      type: BuiltinDriftType.dateTime,
      isNullable: false,
      requiredDuringInsert: true)
    ..owningResultSet = this;
  @override
  late final TableColumn<Uint8List> profilePicture = TableColumn<Uint8List>(
      name: 'profile_picture',
      type: BuiltinDriftType.byteArray,
      isNullable: true,
      requiredDuringInsert: false)
    ..owningResultSet = this;
  @override
  late final TableColumnWithTypeConverter<Preferences?, String> preferences =
      TableColumn<String>(
              name: 'preferences',
              type: BuiltinDriftType.text,
              isNullable: true,
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
  Set<TableColumn> get primaryKey => {id};
  @override
  User? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return User(
        id: row.readWithType(positions[0], BuiltinDriftType.int)!,
        name: row.readWithType(positions[1], BuiltinDriftType.text)!,
        birthDate: row.readWithType(positions[2], BuiltinDriftType.dateTime)!,
        profilePicture:
            row.readWithType(positions[3], BuiltinDriftType.byteArray),
        preferences: $UsersTable.$converterpreferences
            .fromSql(row.readWithType(positions[4], BuiltinDriftType.text)),
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
      map['preferences'] = Variable<String>(
          $UsersTable.$converterpreferences.toSql(preferences));
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
      User.fromJson(
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
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
      map['preferences'] = Variable<String>(
          $UsersTable.$converterpreferences.toSql(preferences.value));
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
      type: BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: true)
    ..owningResultSet = this;
  @override
  late final TableColumn<int> secondUser = TableColumn<int>(
      name: 'second_user',
      type: BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: true)
    ..owningResultSet = this;
  @override
  late final TableColumn<bool> reallyGoodFriends = TableColumn<bool>(
      name: 'really_good_friends',
      type: BuiltinDriftType.bool,
      isNullable: false,
      requiredDuringInsert: false,
      constraints: () => [ColumnDefaultConstraint<bool>(const Literal(false))])
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
  Friendship? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      // Not part of row if non-nullable column "firstUser" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return Friendship(
        firstUser: row.readWithType(positions[0], BuiltinDriftType.int)!,
        secondUser: row.readWithType(positions[1], BuiltinDriftType.int)!,
        reallyGoodFriends:
            row.readWithType(positions[2], BuiltinDriftType.bool)!,
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
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
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

abstract base class _$Database extends GeneratedDatabase {
  _$Database(super.implementation);
  late final $UsersTable users = $UsersTable();
  late final $FriendshipsTable friendships = $FriendshipsTable();
  Selectable<User> mostPopularUsers(int amount) {
    return customSelectMapped<User>(
        query:
            'SELECT id AS _c0, name AS _c1, birth_date AS _c2, profile_picture AS _c3, preferences AS _c4 FROM users AS u ORDER BY (SELECT COUNT(*) FROM friendships WHERE first_user = u.id OR second_user = u.id) DESC LIMIT ?1',
        variables: [(dialect.intType, amount)],
        readsFrom: {
          users,
          friendships,
        },
        createMapper: (DriftResultSet resultSet) {
          final map_0 = users.createMapperFromPositions(const [
            (index: 0, name: '_c0'),
            (index: 1, name: '_c1'),
            (index: 2, name: '_c2'),
            (index: 3, name: '_c3'),
            (index: 4, name: '_c4'),
          ]);

          return (DriftRow row) => map_0(row)!;
        });
  }

  Selectable<int> amountOfGoodFriends(int user) {
    return customSelectMapped<int>(
        query:
            'SELECT COUNT(*) AS _c0 FROM friendships AS f WHERE f.really_good_friends = TRUE AND(f.first_user = ?1 OR f.second_user = ?1)',
        variables: [(dialect.intType, user)],
        readsFrom: {
          friendships,
        },
        createMapper: (DriftResultSet resultSet) {
          final type$int = dialect.intType;

          return (DriftRow row) =>
              row.readWithType(const (index: 0, name: '_c0'), type$int)!;
        });
  }

  Selectable<FriendshipsOfResult> friendshipsOf(int user) {
    return customSelectMapped<FriendshipsOfResult>(
        query:
            'SELECT f.really_good_friends,"user"."id" AS "nested_0.id", "user"."name" AS "nested_0.name", "user"."birth_date" AS "nested_0.birth_date", "user"."profile_picture" AS "nested_0.profile_picture", "user"."preferences" AS "nested_0.preferences" FROM friendships AS f INNER JOIN users AS user ON user.id IN (f.first_user, f.second_user) AND user.id != ?1 WHERE(f.first_user = ?1 OR f.second_user = ?1)',
        variables: [(dialect.intType, user)],
        readsFrom: {
          friendships,
          users,
        },
        createMapper: (DriftResultSet resultSet) {
          final type$bool = dialect.boolType;
          final map_0 = users.createMapperFromPositions(const [
            (index: 1, name: 'nested_0.id'),
            (index: 2, name: 'nested_0.name'),
            (index: 3, name: 'nested_0.birth_date'),
            (index: 4, name: 'nested_0.profile_picture'),
            (index: 5, name: 'nested_0.preferences'),
          ]);

          return (DriftRow row) => FriendshipsOfResult(
                reallyGoodFriends: row.readWithType(
                    const (index: 0, name: 'really_good_friends'), type$bool)!,
                user: map_0(row)!,
              );
        });
  }

  Selectable<int> userCount() {
    return customSelectMapped<int>(
        query: 'SELECT COUNT(id) AS _c0 FROM users',
        variables: [],
        readsFrom: {
          users,
        },
        createMapper: (DriftResultSet resultSet) {
          final type$int = dialect.intType;

          return (DriftRow row) =>
              row.readWithType(const (index: 0, name: '_c0'), type$int)!;
        });
  }

  Selectable<Preferences?> settingsFor(int user) {
    return customSelectMapped<Preferences?>(
        query: 'SELECT preferences FROM users WHERE id = ?1',
        variables: [(dialect.intType, user)],
        readsFrom: {
          users,
        },
        createMapper: (DriftResultSet resultSet) {
          final type$text = dialect.textType;

          return (DriftRow row) => $UsersTable.$converterpreferences.fromSql(row
              .readWithType(const (index: 0, name: 'preferences'), type$text));
        });
  }

  Selectable<User> usersById(List<int> var1) {
    var $arrayStartIndex = 1;
    final expandedvar1 = $expandVar($arrayStartIndex, var1.length);
    $arrayStartIndex += var1.length;
    return customSelectMapped<User>(
        query:
            'SELECT id AS _c0, name AS _c1, birth_date AS _c2, profile_picture AS _c3, preferences AS _c4 FROM users WHERE id IN ($expandedvar1)',
        variables: [for (var $ in var1) (dialect.intType, $)],
        readsFrom: {
          users,
        },
        createMapper: (DriftResultSet resultSet) {
          final map_0 = users.createMapperFromPositions(const [
            (index: 0, name: '_c0'),
            (index: 1, name: '_c1'),
            (index: 2, name: '_c2'),
            (index: 3, name: '_c3'),
            (index: 4, name: '_c4'),
          ]);

          return (DriftRow row) => map_0(row)!;
        });
  }

  Future<List<Friendship>> returning(int var1, int var2, bool var3) {
    return customWriteReturning(
        'INSERT INTO friendships VALUES (?1, ?2, ?3) RETURNING *',
        variables: [
          (dialect.intType, var1),
          (dialect.intType, var2),
          (dialect.boolType, var3)
        ],
        updates: {
          friendships
        }).then((rows) {
      final map_0 = friendships.createMapperFromPositions(const [
        (index: 0, name: 'first_user'),
        (index: 1, name: 'second_user'),
        (index: 2, name: 'really_good_friends'),
      ]);

      return rows.map((row) => map_0(row)!).toList();
    });
  }

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [users, friendships];
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
