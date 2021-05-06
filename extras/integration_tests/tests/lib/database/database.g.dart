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
  factory User.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
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
    serializer ??= moorRuntimeOptions.defaultSerializer;
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
    serializer ??= moorRuntimeOptions.defaultSerializer;
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
  int get hashCode => $mrjf($mrjc(
      id.hashCode,
      $mrjc(
          name.hashCode,
          $mrjc(birthDate.hashCode,
              $mrjc(profilePicture.hashCode, preferences.hashCode)))));
  @override
  bool operator ==(dynamic other) =>
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
  @override
  late final GeneratedIntColumn id = _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false,
        hasAutoIncrement: true, declaredAsPrimaryKey: true);
  }

  final VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedTextColumn name = _constructName();
  GeneratedTextColumn _constructName() {
    return GeneratedTextColumn(
      'name',
      $tableName,
      false,
    );
  }

  final VerificationMeta _birthDateMeta = const VerificationMeta('birthDate');
  @override
  late final GeneratedDateTimeColumn birthDate = _constructBirthDate();
  GeneratedDateTimeColumn _constructBirthDate() {
    return GeneratedDateTimeColumn(
      'birth_date',
      $tableName,
      false,
    );
  }

  final VerificationMeta _profilePictureMeta =
      const VerificationMeta('profilePicture');
  @override
  late final GeneratedBlobColumn profilePicture = _constructProfilePicture();
  GeneratedBlobColumn _constructProfilePicture() {
    return GeneratedBlobColumn(
      'profile_picture',
      $tableName,
      true,
    );
  }

  final VerificationMeta _preferencesMeta =
      const VerificationMeta('preferences');
  @override
  late final GeneratedTextColumn preferences = _constructPreferences();
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
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return User.fromData(data, _db, prefix: effectivePrefix);
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
  factory Friendship.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
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
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Friendship(
      firstUser: serializer.fromJson<int>(json['firstUser']),
      secondUser: serializer.fromJson<int>(json['secondUser']),
      reallyGoodFriends: serializer.fromJson<bool>(json['reallyGoodFriends']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
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
  int get hashCode => $mrjf($mrjc(firstUser.hashCode,
      $mrjc(secondUser.hashCode, reallyGoodFriends.hashCode)));
  @override
  bool operator ==(dynamic other) =>
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
  @override
  late final GeneratedIntColumn firstUser = _constructFirstUser();
  GeneratedIntColumn _constructFirstUser() {
    return GeneratedIntColumn(
      'first_user',
      $tableName,
      false,
    );
  }

  final VerificationMeta _secondUserMeta = const VerificationMeta('secondUser');
  @override
  late final GeneratedIntColumn secondUser = _constructSecondUser();
  GeneratedIntColumn _constructSecondUser() {
    return GeneratedIntColumn(
      'second_user',
      $tableName,
      false,
    );
  }

  final VerificationMeta _reallyGoodFriendsMeta =
      const VerificationMeta('reallyGoodFriends');
  @override
  late final GeneratedBoolColumn reallyGoodFriends =
      _constructReallyGoodFriends();
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
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Friendship.fromData(data, _db, prefix: effectivePrefix);
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
        'SELECT * FROM users u ORDER BY (SELECT COUNT(*) FROM friendships WHERE first_user = u.id OR second_user = u.id) DESC LIMIT :amount',
        variables: [Variable<int>(amount)],
        readsFrom: {users, friendships}).map(users.mapFromRow);
  }

  Selectable<int> amountOfGoodFriends(int user) {
    return customSelect(
        'SELECT COUNT(*) FROM friendships f WHERE f.really_good_friends AND (f.first_user = :user OR f.second_user = :user)',
        variables: [
          Variable<int>(user)
        ],
        readsFrom: {
          friendships
        }).map((QueryRow row) => row.read<int>('COUNT(*)'));
  }

  Selectable<FriendshipsOfResult> friendshipsOf(int user) {
    return customSelect(
        'SELECT \n          f.really_good_friends, "user"."id" AS "nested_0.id", "user"."name" AS "nested_0.name", "user"."birth_date" AS "nested_0.birth_date", "user"."profile_picture" AS "nested_0.profile_picture", "user"."preferences" AS "nested_0.preferences"\n       FROM friendships f\n         INNER JOIN users user ON user.id IN (f.first_user, f.second_user) AND\n             user.id != :user\n       WHERE (f.first_user = :user OR f.second_user = :user)',
        variables: [Variable<int>(user)],
        readsFrom: {friendships, users}).map((QueryRow row) {
      return FriendshipsOfResult(
        reallyGoodFriends: row.read<bool>('really_good_friends'),
        user: users.mapFromRow(row, tablePrefix: 'nested_0'),
      );
    });
  }

  Selectable<int> userCount() {
    return customSelect('SELECT COUNT(id) FROM users',
        variables: [],
        readsFrom: {users}).map((QueryRow row) => row.read<int>('COUNT(id)'));
  }

  Selectable<Preferences?> settingsFor(int user) {
    return customSelect('SELECT preferences FROM users WHERE id = :user',
            variables: [Variable<int>(user)], readsFrom: {users})
        .map((QueryRow row) => $UsersTable.$converter0
            .mapToDart(row.read<String?>('preferences')));
  }

  Selectable<User> usersById(List<int> var1) {
    var $arrayStartIndex = 1;
    final expandedvar1 = $expandVar($arrayStartIndex, var1.length);
    $arrayStartIndex += var1.length;
    return customSelect('SELECT * FROM users WHERE id IN ($expandedvar1)',
        variables: [for (var $ in var1) Variable<int>($)],
        readsFrom: {users}).map(users.mapFromRow);
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
  int get hashCode => $mrjf($mrjc(reallyGoodFriends.hashCode, user.hashCode));
  @override
  bool operator ==(dynamic other) =>
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
