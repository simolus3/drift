// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

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

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
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
  User(
      {required this.id,
      required this.name,
      required this.birthDate,
      this.profilePicture,
      this.preferences});
  factory User.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return User(
      id: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      name: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}name'])!,
      birthDate: const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}birth_date'])!,
      profilePicture: const BlobType()
          .mapFromDatabaseResponse(data['${effectivePrefix}profile_picture']),
      preferences: $UsersTable.$converter0.mapToDart(const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}preferences'])),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['birth_date'] = Variable<DateTime>(birthDate);
    if (!nullToAbsent || profilePicture != null) {
      map['profile_picture'] = Variable<Uint8List?>(profilePicture);
    }
    if (!nullToAbsent || preferences != null) {
      final converter = $UsersTable.$converter0;
      map['preferences'] = Variable<String?>(converter.mapToSql(preferences));
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
          Uint8List? profilePicture,
          Preferences? preferences}) =>
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
  int get hashCode =>
      Object.hash(id, name, birthDate, profilePicture, preferences);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.name == this.name &&
          other.birthDate == this.birthDate &&
          other.profilePicture == this.profilePicture &&
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
    Expression<Uint8List?>? profilePicture,
    Expression<Preferences?>? preferences,
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
      map['profile_picture'] = Variable<Uint8List?>(profilePicture.value);
    }
    if (preferences.present) {
      final converter = $UsersTable.$converter0;
      map['preferences'] =
          Variable<String?>(converter.mapToSql(preferences.value));
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

class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  final GeneratedDatabase _db;
  final String? _alias;
  $UsersTable(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int?> id = GeneratedColumn<int?>(
      'id', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultConstraints: 'PRIMARY KEY AUTOINCREMENT');
  final VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String?> name = GeneratedColumn<String?>(
      'name', aliasedName, false,
      type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _birthDateMeta = const VerificationMeta('birthDate');
  late final GeneratedColumn<DateTime?> birthDate = GeneratedColumn<DateTime?>(
      'birth_date', aliasedName, false,
      type: const IntType(), requiredDuringInsert: true);
  final VerificationMeta _profilePictureMeta =
      const VerificationMeta('profilePicture');
  late final GeneratedColumn<Uint8List?> profilePicture =
      GeneratedColumn<Uint8List?>('profile_picture', aliasedName, true,
          type: const BlobType(), requiredDuringInsert: false);
  final VerificationMeta _preferencesMeta =
      const VerificationMeta('preferences');
  late final GeneratedColumnWithTypeConverter<Preferences, String?>
      preferences = GeneratedColumn<String?>('preferences', aliasedName, true,
              type: const StringType(), requiredDuringInsert: false)
          .withConverter<Preferences>($UsersTable.$converter0);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, birthDate, profilePicture, preferences];
  @override
  String get aliasedName => _alias ?? 'users';
  @override
  String get actualTableName => 'users';
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
    return User.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(_db, alias);
  }

  static TypeConverter<Preferences, String> $converter0 =
      const PreferenceConverter();
}

class Friendship extends DataClass implements Insertable<Friendship> {
  final int firstUser;
  final int secondUser;
  final bool reallyGoodFriends;
  Friendship(
      {required this.firstUser,
      required this.secondUser,
      required this.reallyGoodFriends});
  factory Friendship.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return Friendship(
      firstUser: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}first_user'])!,
      secondUser: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}second_user'])!,
      reallyGoodFriends: const BoolType().mapFromDatabaseResponse(
          data['${effectivePrefix}really_good_friends'])!,
    );
  }
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
  const FriendshipsCompanion({
    this.firstUser = const Value.absent(),
    this.secondUser = const Value.absent(),
    this.reallyGoodFriends = const Value.absent(),
  });
  FriendshipsCompanion.insert({
    required int firstUser,
    required int secondUser,
    this.reallyGoodFriends = const Value.absent(),
  })  : firstUser = Value(firstUser),
        secondUser = Value(secondUser);
  static Insertable<Friendship> custom({
    Expression<int>? firstUser,
    Expression<int>? secondUser,
    Expression<bool>? reallyGoodFriends,
  }) {
    return RawValuesInsertable({
      if (firstUser != null) 'first_user': firstUser,
      if (secondUser != null) 'second_user': secondUser,
      if (reallyGoodFriends != null) 'really_good_friends': reallyGoodFriends,
    });
  }

  FriendshipsCompanion copyWith(
      {Value<int>? firstUser,
      Value<int>? secondUser,
      Value<bool>? reallyGoodFriends}) {
    return FriendshipsCompanion(
      firstUser: firstUser ?? this.firstUser,
      secondUser: secondUser ?? this.secondUser,
      reallyGoodFriends: reallyGoodFriends ?? this.reallyGoodFriends,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FriendshipsCompanion(')
          ..write('firstUser: $firstUser, ')
          ..write('secondUser: $secondUser, ')
          ..write('reallyGoodFriends: $reallyGoodFriends')
          ..write(')'))
        .toString();
  }
}

class $FriendshipsTable extends Friendships
    with TableInfo<$FriendshipsTable, Friendship> {
  final GeneratedDatabase _db;
  final String? _alias;
  $FriendshipsTable(this._db, [this._alias]);
  final VerificationMeta _firstUserMeta = const VerificationMeta('firstUser');
  late final GeneratedColumn<int?> firstUser = GeneratedColumn<int?>(
      'first_user', aliasedName, false,
      type: const IntType(), requiredDuringInsert: true);
  final VerificationMeta _secondUserMeta = const VerificationMeta('secondUser');
  late final GeneratedColumn<int?> secondUser = GeneratedColumn<int?>(
      'second_user', aliasedName, false,
      type: const IntType(), requiredDuringInsert: true);
  final VerificationMeta _reallyGoodFriendsMeta =
      const VerificationMeta('reallyGoodFriends');
  late final GeneratedColumn<bool?> reallyGoodFriends = GeneratedColumn<bool?>(
      'really_good_friends', aliasedName, false,
      type: const BoolType(),
      requiredDuringInsert: false,
      defaultConstraints: 'CHECK (really_good_friends IN (0, 1))',
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [firstUser, secondUser, reallyGoodFriends];
  @override
  String get aliasedName => _alias ?? 'friendships';
  @override
  String get actualTableName => 'friendships';
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
    return Friendship.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $FriendshipsTable createAlias(String alias) {
    return $FriendshipsTable(_db, alias);
  }
}

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  _$Database.connect(DatabaseConnection c) : super.connect(c);
  late final $UsersTable users = $UsersTable(this);
  late final $FriendshipsTable friendships = $FriendshipsTable(this);
  Selectable<User> mostPopularUsers(int amount) {
    return customSelect(
        'SELECT * FROM users AS u ORDER BY (SELECT COUNT(*) FROM friendships WHERE first_user = u.id OR second_user = u.id) DESC LIMIT ?1',
        variables: [
          Variable<int>(amount)
        ],
        readsFrom: {
          users,
          friendships,
        }).map(users.mapFromRow);
  }

  Selectable<int> amountOfGoodFriends(int user) {
    return customSelect(
        'SELECT COUNT(*) AS _c0 FROM friendships AS f WHERE f.really_good_friends = 1 AND(f.first_user = ?1 OR f.second_user = ?1)',
        variables: [
          Variable<int>(user)
        ],
        readsFrom: {
          friendships,
        }).map((QueryRow row) => row.read<int>('_c0'));
  }

  Selectable<FriendshipsOfResult> friendshipsOf(int user) {
    return customSelect(
        'SELECT f.really_good_friends,"user"."id" AS "nested_0.id", "user"."name" AS "nested_0.name", "user"."birth_date" AS "nested_0.birth_date", "user"."profile_picture" AS "nested_0.profile_picture", "user"."preferences" AS "nested_0.preferences" FROM friendships AS f INNER JOIN users AS "user" ON "user".id IN (f.first_user, f.second_user) AND "user".id != ?1 WHERE(f.first_user = ?1 OR f.second_user = ?1)',
        variables: [
          Variable<int>(user)
        ],
        readsFrom: {
          friendships,
          users,
        }).map((QueryRow row) {
      return FriendshipsOfResult(
        reallyGoodFriends: row.read<bool>('really_good_friends'),
        user: users.mapFromRow(row, tablePrefix: 'nested_0'),
      );
    });
  }

  Selectable<int> userCount() {
    return customSelect('SELECT COUNT(id) AS _c0 FROM users',
        variables: [],
        readsFrom: {
          users,
        }).map((QueryRow row) => row.read<int>('_c0'));
  }

  Selectable<Preferences?> settingsFor(int user) {
    return customSelect('SELECT preferences FROM users WHERE id = ?1',
        variables: [
          Variable<int>(user)
        ],
        readsFrom: {
          users,
        }).map((QueryRow row) =>
        $UsersTable.$converter0.mapToDart(row.read<String?>('preferences')));
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
        }).map(users.mapFromRow);
  }

  Future<List<Friendship>> returning(int var1, int var2, bool var3) {
    return customWriteReturning(
        'INSERT INTO friendships VALUES (?1, ?2, ?3) RETURNING *',
        variables: [
          Variable<int>(var1),
          Variable<int>(var2),
          Variable<bool>(var3)
        ],
        updates: {
          friendships
        }).then((rows) => rows.map(friendships.mapFromRow).toList());
  }

  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
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
