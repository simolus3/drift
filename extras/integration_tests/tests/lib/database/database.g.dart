// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Preferences _$PreferencesFromJson(Map<String, dynamic> json) {
  return Preferences(
    json['receiveEmails'] as bool,
  );
}

Map<String, dynamic> _$PreferencesToJson(Preferences instance) =>
    <String, dynamic>{
      'receiveEmails': instance.receiveEmails,
    };

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps
class User extends DataClass implements Insertable<User> {
  final int id;
  final String name;
  final DateTime birthDate;
  final Uint8List profilePicture;
  final Preferences preferences;
  User(
      {@required this.id,
      @required this.name,
      @required this.birthDate,
      this.profilePicture,
      this.preferences});
  factory User.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    final dateTimeType = db.typeSystem.forDartType<DateTime>();
    final uint8ListType = db.typeSystem.forDartType<Uint8List>();
    return User(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}id']),
      name: stringType.mapFromDatabaseResponse(data['${effectivePrefix}name']),
      birthDate: dateTimeType
          .mapFromDatabaseResponse(data['${effectivePrefix}birth_date']),
      profilePicture: uint8ListType
          .mapFromDatabaseResponse(data['${effectivePrefix}profile_picture']),
      preferences: $UsersTable.$converter0.mapToDart(stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}preferences'])),
    );
  }
  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return User(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      birthDate: serializer.fromJson<DateTime>(json['born_on']),
      profilePicture: serializer.fromJson<Uint8List>(json['profilePicture']),
      preferences: serializer.fromJson<Preferences>(json['preferences']),
    );
  }
  @override
  Map<String, dynamic> toJson(
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return {
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'born_on': serializer.toJson<DateTime>(birthDate),
      'profilePicture': serializer.toJson<Uint8List>(profilePicture),
      'preferences': serializer.toJson<Preferences>(preferences),
    };
  }

  @override
  T createCompanion<T extends UpdateCompanion<User>>(bool nullToAbsent) {
    return UsersCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      birthDate: birthDate == null && nullToAbsent
          ? const Value.absent()
          : Value(birthDate),
      profilePicture: profilePicture == null && nullToAbsent
          ? const Value.absent()
          : Value(profilePicture),
      preferences: preferences == null && nullToAbsent
          ? const Value.absent()
          : Value(preferences),
    ) as T;
  }

  User copyWith(
          {int id,
          String name,
          DateTime birthDate,
          Uint8List profilePicture,
          Preferences preferences}) =>
      User(
        id: id ?? this.id,
        name: name ?? this.name,
        birthDate: birthDate ?? this.birthDate,
        profilePicture: profilePicture ?? this.profilePicture,
        preferences: preferences ?? this.preferences,
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
  int get hashCode => $mrjf($mrjc(
      id.hashCode,
      $mrjc(
          name.hashCode,
          $mrjc(birthDate.hashCode,
              $mrjc(profilePicture.hashCode, preferences.hashCode)))));
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is User &&
          other.id == id &&
          other.name == name &&
          other.birthDate == birthDate &&
          other.profilePicture == profilePicture &&
          other.preferences == preferences);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> birthDate;
  final Value<Uint8List> profilePicture;
  final Value<Preferences> preferences;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.profilePicture = const Value.absent(),
    this.preferences = const Value.absent(),
  });
  UsersCompanion copyWith(
      {Value<int> id,
      Value<String> name,
      Value<DateTime> birthDate,
      Value<Uint8List> profilePicture,
      Value<Preferences> preferences}) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      profilePicture: profilePicture ?? this.profilePicture,
      preferences: preferences ?? this.preferences,
    );
  }
}

class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  final GeneratedDatabase _db;
  final String _alias;
  $UsersTable(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  GeneratedIntColumn _id;
  @override
  GeneratedIntColumn get id => _id ??= _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false, hasAutoIncrement: true);
  }

  final VerificationMeta _nameMeta = const VerificationMeta('name');
  GeneratedTextColumn _name;
  @override
  GeneratedTextColumn get name => _name ??= _constructName();
  GeneratedTextColumn _constructName() {
    return GeneratedTextColumn(
      'name',
      $tableName,
      false,
    );
  }

  final VerificationMeta _birthDateMeta = const VerificationMeta('birthDate');
  GeneratedDateTimeColumn _birthDate;
  @override
  GeneratedDateTimeColumn get birthDate => _birthDate ??= _constructBirthDate();
  GeneratedDateTimeColumn _constructBirthDate() {
    return GeneratedDateTimeColumn(
      'birth_date',
      $tableName,
      false,
    );
  }

  final VerificationMeta _profilePictureMeta =
      const VerificationMeta('profilePicture');
  GeneratedBlobColumn _profilePicture;
  @override
  GeneratedBlobColumn get profilePicture =>
      _profilePicture ??= _constructProfilePicture();
  GeneratedBlobColumn _constructProfilePicture() {
    return GeneratedBlobColumn(
      'profile_picture',
      $tableName,
      true,
    );
  }

  final VerificationMeta _preferencesMeta =
      const VerificationMeta('preferences');
  GeneratedTextColumn _preferences;
  @override
  GeneratedTextColumn get preferences =>
      _preferences ??= _constructPreferences();
  GeneratedTextColumn _constructPreferences() {
    return GeneratedTextColumn(
      'preferences',
      $tableName,
      true,
    );
  }

  @override
  List<GeneratedColumn> get $columns =>
      [id, name, birthDate, profilePicture, preferences];
  @override
  $UsersTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'users';
  @override
  final String actualTableName = 'users';
  @override
  VerificationContext validateIntegrity(UsersCompanion d,
      {bool isInserting = false}) {
    final context = VerificationContext();
    if (d.id.present) {
      context.handle(_idMeta, id.isAcceptableValue(d.id.value, _idMeta));
    } else if (id.isRequired && isInserting) {
      context.missing(_idMeta);
    }
    if (d.name.present) {
      context.handle(
          _nameMeta, name.isAcceptableValue(d.name.value, _nameMeta));
    } else if (name.isRequired && isInserting) {
      context.missing(_nameMeta);
    }
    if (d.birthDate.present) {
      context.handle(_birthDateMeta,
          birthDate.isAcceptableValue(d.birthDate.value, _birthDateMeta));
    } else if (birthDate.isRequired && isInserting) {
      context.missing(_birthDateMeta);
    }
    if (d.profilePicture.present) {
      context.handle(
          _profilePictureMeta,
          profilePicture.isAcceptableValue(
              d.profilePicture.value, _profilePictureMeta));
    } else if (profilePicture.isRequired && isInserting) {
      context.missing(_profilePictureMeta);
    }
    context.handle(_preferencesMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return User.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Map<String, Variable> entityToSql(UsersCompanion d) {
    final map = <String, Variable>{};
    if (d.id.present) {
      map['id'] = Variable<int, IntType>(d.id.value);
    }
    if (d.name.present) {
      map['name'] = Variable<String, StringType>(d.name.value);
    }
    if (d.birthDate.present) {
      map['birth_date'] = Variable<DateTime, DateTimeType>(d.birthDate.value);
    }
    if (d.profilePicture.present) {
      map['profile_picture'] =
          Variable<Uint8List, BlobType>(d.profilePicture.value);
    }
    if (d.preferences.present) {
      final converter = $UsersTable.$converter0;
      map['preferences'] =
          Variable<String, StringType>(converter.mapToSql(d.preferences.value));
    }
    return map;
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(_db, alias);
  }

  static PreferenceConverter $converter0 = const PreferenceConverter();
}

class Friendship extends DataClass implements Insertable<Friendship> {
  final int firstUser;
  final int secondUser;
  final bool reallyGoodFriends;
  Friendship(
      {@required this.firstUser,
      @required this.secondUser,
      @required this.reallyGoodFriends});
  factory Friendship.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final boolType = db.typeSystem.forDartType<bool>();
    return Friendship(
      firstUser:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}first_user']),
      secondUser: intType
          .mapFromDatabaseResponse(data['${effectivePrefix}second_user']),
      reallyGoodFriends: boolType.mapFromDatabaseResponse(
          data['${effectivePrefix}really_good_friends']),
    );
  }
  factory Friendship.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return Friendship(
      firstUser: serializer.fromJson<int>(json['firstUser']),
      secondUser: serializer.fromJson<int>(json['secondUser']),
      reallyGoodFriends: serializer.fromJson<bool>(json['reallyGoodFriends']),
    );
  }
  @override
  Map<String, dynamic> toJson(
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return {
      'firstUser': serializer.toJson<int>(firstUser),
      'secondUser': serializer.toJson<int>(secondUser),
      'reallyGoodFriends': serializer.toJson<bool>(reallyGoodFriends),
    };
  }

  @override
  T createCompanion<T extends UpdateCompanion<Friendship>>(bool nullToAbsent) {
    return FriendshipsCompanion(
      firstUser: firstUser == null && nullToAbsent
          ? const Value.absent()
          : Value(firstUser),
      secondUser: secondUser == null && nullToAbsent
          ? const Value.absent()
          : Value(secondUser),
      reallyGoodFriends: reallyGoodFriends == null && nullToAbsent
          ? const Value.absent()
          : Value(reallyGoodFriends),
    ) as T;
  }

  Friendship copyWith(
          {int firstUser, int secondUser, bool reallyGoodFriends}) =>
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
  int get hashCode => $mrjf($mrjc(firstUser.hashCode,
      $mrjc(secondUser.hashCode, reallyGoodFriends.hashCode)));
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is Friendship &&
          other.firstUser == firstUser &&
          other.secondUser == secondUser &&
          other.reallyGoodFriends == reallyGoodFriends);
}

class FriendshipsCompanion extends UpdateCompanion<Friendship> {
  final Value<int> firstUser;
  final Value<int> secondUser;
  final Value<bool> reallyGoodFriends;
  const FriendshipsCompanion({
    this.firstUser = const Value.absent(),
    this.secondUser = const Value.absent(),
    this.reallyGoodFriends = const Value.absent(),
  });
  FriendshipsCompanion copyWith(
      {Value<int> firstUser,
      Value<int> secondUser,
      Value<bool> reallyGoodFriends}) {
    return FriendshipsCompanion(
      firstUser: firstUser ?? this.firstUser,
      secondUser: secondUser ?? this.secondUser,
      reallyGoodFriends: reallyGoodFriends ?? this.reallyGoodFriends,
    );
  }
}

class $FriendshipsTable extends Friendships
    with TableInfo<$FriendshipsTable, Friendship> {
  final GeneratedDatabase _db;
  final String _alias;
  $FriendshipsTable(this._db, [this._alias]);
  final VerificationMeta _firstUserMeta = const VerificationMeta('firstUser');
  GeneratedIntColumn _firstUser;
  @override
  GeneratedIntColumn get firstUser => _firstUser ??= _constructFirstUser();
  GeneratedIntColumn _constructFirstUser() {
    return GeneratedIntColumn(
      'first_user',
      $tableName,
      false,
    );
  }

  final VerificationMeta _secondUserMeta = const VerificationMeta('secondUser');
  GeneratedIntColumn _secondUser;
  @override
  GeneratedIntColumn get secondUser => _secondUser ??= _constructSecondUser();
  GeneratedIntColumn _constructSecondUser() {
    return GeneratedIntColumn(
      'second_user',
      $tableName,
      false,
    );
  }

  final VerificationMeta _reallyGoodFriendsMeta =
      const VerificationMeta('reallyGoodFriends');
  GeneratedBoolColumn _reallyGoodFriends;
  @override
  GeneratedBoolColumn get reallyGoodFriends =>
      _reallyGoodFriends ??= _constructReallyGoodFriends();
  GeneratedBoolColumn _constructReallyGoodFriends() {
    return GeneratedBoolColumn('really_good_friends', $tableName, false,
        defaultValue: const Constant(false));
  }

  @override
  List<GeneratedColumn> get $columns =>
      [firstUser, secondUser, reallyGoodFriends];
  @override
  $FriendshipsTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'friendships';
  @override
  final String actualTableName = 'friendships';
  @override
  VerificationContext validateIntegrity(FriendshipsCompanion d,
      {bool isInserting = false}) {
    final context = VerificationContext();
    if (d.firstUser.present) {
      context.handle(_firstUserMeta,
          firstUser.isAcceptableValue(d.firstUser.value, _firstUserMeta));
    } else if (firstUser.isRequired && isInserting) {
      context.missing(_firstUserMeta);
    }
    if (d.secondUser.present) {
      context.handle(_secondUserMeta,
          secondUser.isAcceptableValue(d.secondUser.value, _secondUserMeta));
    } else if (secondUser.isRequired && isInserting) {
      context.missing(_secondUserMeta);
    }
    if (d.reallyGoodFriends.present) {
      context.handle(
          _reallyGoodFriendsMeta,
          reallyGoodFriends.isAcceptableValue(
              d.reallyGoodFriends.value, _reallyGoodFriendsMeta));
    } else if (reallyGoodFriends.isRequired && isInserting) {
      context.missing(_reallyGoodFriendsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {firstUser, secondUser};
  @override
  Friendship map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Friendship.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Map<String, Variable> entityToSql(FriendshipsCompanion d) {
    final map = <String, Variable>{};
    if (d.firstUser.present) {
      map['first_user'] = Variable<int, IntType>(d.firstUser.value);
    }
    if (d.secondUser.present) {
      map['second_user'] = Variable<int, IntType>(d.secondUser.value);
    }
    if (d.reallyGoodFriends.present) {
      map['really_good_friends'] =
          Variable<bool, BoolType>(d.reallyGoodFriends.value);
    }
    return map;
  }

  @override
  $FriendshipsTable createAlias(String alias) {
    return $FriendshipsTable(_db, alias);
  }
}

class AmountOfGoodFriendsResult {
  final int count;
  AmountOfGoodFriendsResult({
    this.count,
  });
}

class UserCountResult {
  final int cOUNTid;
  UserCountResult({
    this.cOUNTid,
  });
}

class SettingsForResult {
  final Preferences preferences;
  SettingsForResult({
    this.preferences,
  });
}

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(const SqlTypeSystem.withDefaults(), e);
  $UsersTable _users;
  $UsersTable get users => _users ??= $UsersTable(this);
  $FriendshipsTable _friendships;
  $FriendshipsTable get friendships => _friendships ??= $FriendshipsTable(this);
  User _rowToUser(QueryRow row) {
    return User(
      id: row.readInt('id'),
      name: row.readString('name'),
      birthDate: row.readDateTime('birth_date'),
      profilePicture: row.readBlob('profile_picture'),
      preferences:
          $UsersTable.$converter0.mapToDart(row.readString('preferences')),
    );
  }

  Future<List<User>> mostPopularUsers(
      int amount,
      {@Deprecated('No longer needed with Moor 1.6 - see the changelog for details')
          QueryEngine operateOn}) {
    return (operateOn ?? this).customSelect(
        'SELECT * FROM users u ORDER BY (SELECT COUNT(*) FROM friendships WHERE first_user = u.id OR second_user = u.id) DESC LIMIT :amount',
        variables: [
          Variable.withInt(amount),
        ]).then((rows) => rows.map(_rowToUser).toList());
  }

  Stream<List<User>> watchMostPopularUsers(int amount) {
    return customSelectStream(
        'SELECT * FROM users u ORDER BY (SELECT COUNT(*) FROM friendships WHERE first_user = u.id OR second_user = u.id) DESC LIMIT :amount',
        variables: [
          Variable.withInt(amount),
        ],
        readsFrom: {
          users,
          friendships
        }).map((rows) => rows.map(_rowToUser).toList());
  }

  AmountOfGoodFriendsResult _rowToAmountOfGoodFriendsResult(QueryRow row) {
    return AmountOfGoodFriendsResult(
      count: row.readInt('COUNT(*)'),
    );
  }

  Future<List<AmountOfGoodFriendsResult>> amountOfGoodFriends(
      int user,
      {@Deprecated('No longer needed with Moor 1.6 - see the changelog for details')
          QueryEngine operateOn}) {
    return (operateOn ?? this).customSelect(
        'SELECT COUNT(*) FROM friendships f WHERE f.really_good_friends AND (f.first_user = :user OR f.second_user = :user)',
        variables: [
          Variable.withInt(user),
        ]).then((rows) => rows.map(_rowToAmountOfGoodFriendsResult).toList());
  }

  Stream<List<AmountOfGoodFriendsResult>> watchAmountOfGoodFriends(int user) {
    return customSelectStream(
        'SELECT COUNT(*) FROM friendships f WHERE f.really_good_friends AND (f.first_user = :user OR f.second_user = :user)',
        variables: [
          Variable.withInt(user),
        ],
        readsFrom: {
          friendships
        }).map((rows) => rows.map(_rowToAmountOfGoodFriendsResult).toList());
  }

  Future<List<User>> friendsOf(
      int user,
      {@Deprecated('No longer needed with Moor 1.6 - see the changelog for details')
          QueryEngine operateOn}) {
    return (operateOn ?? this).customSelect(
        'SELECT u.* FROM friendships f\n         INNER JOIN users u ON u.id IN (f.first_user, f.second_user) AND\n           u.id != :user\n         WHERE (f.first_user = :user OR f.second_user = :user)',
        variables: [
          Variable.withInt(user),
        ]).then((rows) => rows.map(_rowToUser).toList());
  }

  Stream<List<User>> watchFriendsOf(int user) {
    return customSelectStream(
        'SELECT u.* FROM friendships f\n         INNER JOIN users u ON u.id IN (f.first_user, f.second_user) AND\n           u.id != :user\n         WHERE (f.first_user = :user OR f.second_user = :user)',
        variables: [
          Variable.withInt(user),
        ],
        readsFrom: {
          friendships,
          users
        }).map((rows) => rows.map(_rowToUser).toList());
  }

  UserCountResult _rowToUserCountResult(QueryRow row) {
    return UserCountResult(
      cOUNTid: row.readInt('COUNT(id)'),
    );
  }

  Future<List<UserCountResult>> userCount(
      {@Deprecated('No longer needed with Moor 1.6 - see the changelog for details')
          QueryEngine operateOn}) {
    return (operateOn ?? this).customSelect('SELECT COUNT(id) FROM users',
        variables: []).then((rows) => rows.map(_rowToUserCountResult).toList());
  }

  Stream<List<UserCountResult>> watchUserCount() {
    return customSelectStream('SELECT COUNT(id) FROM users',
            variables: [], readsFrom: {users})
        .map((rows) => rows.map(_rowToUserCountResult).toList());
  }

  SettingsForResult _rowToSettingsForResult(QueryRow row) {
    return SettingsForResult(
      preferences:
          $UsersTable.$converter0.mapToDart(row.readString('preferences')),
    );
  }

  Future<List<SettingsForResult>> settingsFor(
      int user,
      {@Deprecated('No longer needed with Moor 1.6 - see the changelog for details')
          QueryEngine operateOn}) {
    return (operateOn ?? this).customSelect(
        'SELECT preferences FROM users WHERE id = :user',
        variables: [
          Variable.withInt(user),
        ]).then((rows) => rows.map(_rowToSettingsForResult).toList());
  }

  Stream<List<SettingsForResult>> watchSettingsFor(int user) {
    return customSelectStream('SELECT preferences FROM users WHERE id = :user',
        variables: [
          Variable.withInt(user),
        ],
        readsFrom: {
          users
        }).map((rows) => rows.map(_rowToSettingsForResult).toList());
  }

  @override
  List<TableInfo> get allTables => [users, friendships];
}
