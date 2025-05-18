// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:modular/src/users.drift.dart' as i1;
import 'package:modular/src/preferences.dart' as i2;
import 'dart:typed_data' as i3;

class Users extends i0.Table
    with i0.ResultSet<i1.User, Users>
    implements i0.GeneratedTable<i1.User, Users> {
  @override
  final String? alias;
  Users([this.alias]);
  late final i0.TableColumn<int> id = i0.TableColumn<int>(
      name: 'id',
      type: i0.BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: false,
      constraints: () =>
          [i0.ColumnConstraint.customSql('NOT NULL PRIMARY KEY')])
    ..owningResultSet = this;
  late final i0.TableColumn<String> name = i0.TableColumn<String>(
      name: 'name',
      type: i0.BuiltinDriftType.text,
      isNullable: false,
      requiredDuringInsert: true,
      constraints: () => [i0.ColumnConstraint.customSql('NOT NULL')])
    ..owningResultSet = this;
  late final i0.TableColumn<String> biography = i0.TableColumn<String>(
      name: 'biography',
      type: i0.BuiltinDriftType.text,
      isNullable: true,
      requiredDuringInsert: false,
      constraints: () => [i0.ColumnConstraint.customSql('')])
    ..owningResultSet = this;
  late final i0.TableColumnWithTypeConverter<i2.Preferences?, String>
      preferences = i0.TableColumn<String>(
              name: 'preferences',
              type: i0.BuiltinDriftType.text,
              isNullable: true,
              requiredDuringInsert: false,
              constraints: () => [i0.ColumnConstraint.customSql('')])
          .withConverter<i2.Preferences?>(i1.Users.$converterpreferencesn)
        ..owningResultSet = this;
  late final i0.TableColumn<i3.Uint8List> profilePicture =
      i0.TableColumn<i3.Uint8List>(
          name: 'profile_picture',
          type: i0.BuiltinDriftType.byteArray,
          isNullable: true,
          requiredDuringInsert: false,
          constraints: () => [i0.ColumnConstraint.customSql('')])
        ..owningResultSet = this;
  @override
  List<i0.TableColumn> get columns =>
      [id, name, biography, preferences, profilePicture];
  @override
  String get entityName => $name;
  static const String $name = 'users';
  @override
  Users asSelfType() => this;

  @override
  Set<i0.TableColumn> get primaryKey => {id};
  @override
  i1.User? Function(i0.DriftRow) createMapperFromPositions(
      List<i0.ColumnPosition> positions) {
    return (i0.DriftRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return i1.User(
        id: row.readWithType(positions[0], i0.BuiltinDriftType.int)!,
        name: row.readWithType(positions[1], i0.BuiltinDriftType.text)!,
        biography: row.readWithType(positions[2], i0.BuiltinDriftType.text),
        preferences: i1.Users.$converterpreferencesn
            .fromSql(row.readWithType(positions[3], i0.BuiltinDriftType.text)),
        profilePicture:
            row.readWithType(positions[4], i0.BuiltinDriftType.byteArray),
      );
    };
  }

  @override
  Users withAlias(String alias) {
    return Users(alias);
  }

  static i0.JsonTypeConverter2<i2.Preferences, String, Map<String, Object?>>
      $converterpreferences = const i2.PreferencesConverter();
  static i0.JsonTypeConverter2<i2.Preferences?, String?, Map<String, Object?>?>
      $converterpreferencesn =
      i0.JsonTypeConverter2.asNullable($converterpreferences);
  @override
  bool get dontWriteConstraints => true;
}

class User extends i0.LegacyDataClass implements i0.Insertable<i1.User> {
  final int id;
  final String name;
  final String? biography;
  final i2.Preferences? preferences;
  final i3.Uint8List? profilePicture;
  const User(
      {required this.id,
      required this.name,
      this.biography,
      this.preferences,
      this.profilePicture});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['name'] = i0.Variable<String>(name);
    if (!nullToAbsent || biography != null) {
      map['biography'] = i0.Variable<String>(biography);
    }
    if (!nullToAbsent || preferences != null) {
      map['preferences'] = i0.Variable<String>(
          i1.Users.$converterpreferencesn.toSql(preferences));
    }
    if (!nullToAbsent || profilePicture != null) {
      map['profile_picture'] = i0.Variable<i3.Uint8List>(profilePicture);
    }
    return map;
  }

  i1.UsersCompanion toCompanion(bool nullToAbsent) {
    return i1.UsersCompanion(
      id: i0.Value(id),
      name: i0.Value(name),
      biography: biography == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(biography),
      preferences: preferences == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(preferences),
      profilePicture: profilePicture == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(profilePicture),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      biography: serializer.fromJson<String?>(json['biography']),
      preferences: i1.Users.$converterpreferencesn.fromJson(
          serializer.fromJson<Map<String, Object?>?>(json['preferences'])),
      profilePicture:
          serializer.fromJson<i3.Uint8List?>(json['profile_picture']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'biography': serializer.toJson<String?>(biography),
      'preferences': serializer.toJson<Map<String, Object?>?>(
          i1.Users.$converterpreferencesn.toJson(preferences)),
      'profile_picture': serializer.toJson<i3.Uint8List?>(profilePicture),
    };
  }

  i1.User copyWith(
          {int? id,
          String? name,
          i0.Value<String?> biography = const i0.Value.absent(),
          i0.Value<i2.Preferences?> preferences = const i0.Value.absent(),
          i0.Value<i3.Uint8List?> profilePicture = const i0.Value.absent()}) =>
      i1.User(
        id: id ?? this.id,
        name: name ?? this.name,
        biography: biography.present ? biography.value : this.biography,
        preferences: preferences.present ? preferences.value : this.preferences,
        profilePicture:
            profilePicture.present ? profilePicture.value : this.profilePicture,
      );
  User copyWithCompanion(i1.UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      biography: data.biography.present ? data.biography.value : this.biography,
      preferences:
          data.preferences.present ? data.preferences.value : this.preferences,
      profilePicture: data.profilePicture.present
          ? data.profilePicture.value
          : this.profilePicture,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('biography: $biography, ')
          ..write('preferences: $preferences, ')
          ..write('profilePicture: $profilePicture')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, biography, preferences,
      i0.$driftBlobEquality.hash(profilePicture));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.User &&
          other.id == this.id &&
          other.name == this.name &&
          other.biography == this.biography &&
          other.preferences == this.preferences &&
          i0.$driftBlobEquality
              .equals(other.profilePicture, this.profilePicture));
}

class UsersCompanion extends i0.UpdateCompanion<i1.User> {
  final i0.Value<int> id;
  final i0.Value<String> name;
  final i0.Value<String?> biography;
  final i0.Value<i2.Preferences?> preferences;
  final i0.Value<i3.Uint8List?> profilePicture;
  const UsersCompanion({
    this.id = const i0.Value.absent(),
    this.name = const i0.Value.absent(),
    this.biography = const i0.Value.absent(),
    this.preferences = const i0.Value.absent(),
    this.profilePicture = const i0.Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const i0.Value.absent(),
    required String name,
    this.biography = const i0.Value.absent(),
    this.preferences = const i0.Value.absent(),
    this.profilePicture = const i0.Value.absent(),
  }) : name = i0.Value(name);
  static i0.Insertable<i1.User> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? name,
    i0.Expression<String>? biography,
    i0.Expression<String>? preferences,
    i0.Expression<i3.Uint8List>? profilePicture,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (biography != null) 'biography': biography,
      if (preferences != null) 'preferences': preferences,
      if (profilePicture != null) 'profile_picture': profilePicture,
    });
  }

  i1.UsersCompanion copyWith(
      {i0.Value<int>? id,
      i0.Value<String>? name,
      i0.Value<String?>? biography,
      i0.Value<i2.Preferences?>? preferences,
      i0.Value<i3.Uint8List?>? profilePicture}) {
    return i1.UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      biography: biography ?? this.biography,
      preferences: preferences ?? this.preferences,
      profilePicture: profilePicture ?? this.profilePicture,
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
    if (biography.present) {
      map['biography'] = i0.Variable<String>(biography.value);
    }
    if (preferences.present) {
      map['preferences'] = i0.Variable<String>(
          i1.Users.$converterpreferencesn.toSql(preferences.value));
    }
    if (profilePicture.present) {
      map['profile_picture'] = i0.Variable<i3.Uint8List>(profilePicture.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('biography: $biography, ')
          ..write('preferences: $preferences, ')
          ..write('profilePicture: $profilePicture')
          ..write(')'))
        .toString();
  }
}

i0.Index get usersName => i0.Index('users_name',
    i0.CustomComponent('CREATE INDEX users_name ON users (name)'));

class Follows extends i0.Table
    with i0.ResultSet<i1.Follow, Follows>
    implements i0.GeneratedTable<i1.Follow, Follows> {
  @override
  final String? alias;
  Follows([this.alias]);
  late final i0.TableColumn<int> followed = i0.TableColumn<int>(
      name: 'followed',
      type: i0.BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: true,
      constraints: () =>
          [i0.ColumnConstraint.customSql('NOT NULL REFERENCES users(id)')])
    ..owningResultSet = this;
  late final i0.TableColumn<int> follower = i0.TableColumn<int>(
      name: 'follower',
      type: i0.BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: true,
      constraints: () =>
          [i0.ColumnConstraint.customSql('NOT NULL REFERENCES users(id)')])
    ..owningResultSet = this;
  @override
  List<i0.TableColumn> get columns => [followed, follower];
  @override
  String get entityName => $name;
  static const String $name = 'follows';
  @override
  Follows asSelfType() => this;

  @override
  Set<i0.TableColumn> get primaryKey => {followed, follower};
  @override
  i1.Follow? Function(i0.DriftRow) createMapperFromPositions(
      List<i0.ColumnPosition> positions) {
    return (i0.DriftRow row) {
      // Not part of row if non-nullable column "followed" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return i1.Follow(
        followed: row.readWithType(positions[0], i0.BuiltinDriftType.int)!,
        follower: row.readWithType(positions[1], i0.BuiltinDriftType.int)!,
      );
    };
  }

  @override
  Follows withAlias(String alias) {
    return Follows(alias);
  }

  @override
  List<String> get customConstraints =>
      const ['PRIMARY KEY(followed, follower)'];
  @override
  bool get dontWriteConstraints => true;
}

class Follow extends i0.LegacyDataClass implements i0.Insertable<i1.Follow> {
  final int followed;
  final int follower;
  const Follow({required this.followed, required this.follower});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['followed'] = i0.Variable<int>(followed);
    map['follower'] = i0.Variable<int>(follower);
    return map;
  }

  i1.FollowsCompanion toCompanion(bool nullToAbsent) {
    return i1.FollowsCompanion(
      followed: i0.Value(followed),
      follower: i0.Value(follower),
    );
  }

  factory Follow.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return Follow(
      followed: serializer.fromJson<int>(json['followed']),
      follower: serializer.fromJson<int>(json['follower']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'followed': serializer.toJson<int>(followed),
      'follower': serializer.toJson<int>(follower),
    };
  }

  i1.Follow copyWith({int? followed, int? follower}) => i1.Follow(
        followed: followed ?? this.followed,
        follower: follower ?? this.follower,
      );
  Follow copyWithCompanion(i1.FollowsCompanion data) {
    return Follow(
      followed: data.followed.present ? data.followed.value : this.followed,
      follower: data.follower.present ? data.follower.value : this.follower,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Follow(')
          ..write('followed: $followed, ')
          ..write('follower: $follower')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(followed, follower);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.Follow &&
          other.followed == this.followed &&
          other.follower == this.follower);
}

class FollowsCompanion extends i0.UpdateCompanion<i1.Follow> {
  final i0.Value<int> followed;
  final i0.Value<int> follower;
  final i0.Value<int> rowid;
  const FollowsCompanion({
    this.followed = const i0.Value.absent(),
    this.follower = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  FollowsCompanion.insert({
    required int followed,
    required int follower,
    this.rowid = const i0.Value.absent(),
  })  : followed = i0.Value(followed),
        follower = i0.Value(follower);
  static i0.Insertable<i1.Follow> custom({
    i0.Expression<int>? followed,
    i0.Expression<int>? follower,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (followed != null) 'followed': followed,
      if (follower != null) 'follower': follower,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.FollowsCompanion copyWith(
      {i0.Value<int>? followed,
      i0.Value<int>? follower,
      i0.Value<int>? rowid}) {
    return i1.FollowsCompanion(
      followed: followed ?? this.followed,
      follower: follower ?? this.follower,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (followed.present) {
      map['followed'] = i0.Variable<int>(followed.value);
    }
    if (follower.present) {
      map['follower'] = i0.Variable<int>(follower.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FollowsCompanion(')
          ..write('followed: $followed, ')
          ..write('follower: $follower, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class PopularUser extends i0.LegacyDataClass {
  final int id;
  final String name;
  final String? biography;
  final i2.Preferences? preferences;
  final i3.Uint8List? profilePicture;
  const PopularUser(
      {required this.id,
      required this.name,
      this.biography,
      this.preferences,
      this.profilePicture});
  factory PopularUser.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return PopularUser(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      biography: serializer.fromJson<String?>(json['biography']),
      preferences: i1.Users.$converterpreferencesn.fromJson(
          serializer.fromJson<Map<String, Object?>?>(json['preferences'])),
      profilePicture:
          serializer.fromJson<i3.Uint8List?>(json['profile_picture']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'biography': serializer.toJson<String?>(biography),
      'preferences': serializer.toJson<Map<String, Object?>?>(
          i1.Users.$converterpreferencesn.toJson(preferences)),
      'profile_picture': serializer.toJson<i3.Uint8List?>(profilePicture),
    };
  }

  i1.PopularUser copyWith(
          {int? id,
          String? name,
          i0.Value<String?> biography = const i0.Value.absent(),
          i0.Value<i2.Preferences?> preferences = const i0.Value.absent(),
          i0.Value<i3.Uint8List?> profilePicture = const i0.Value.absent()}) =>
      i1.PopularUser(
        id: id ?? this.id,
        name: name ?? this.name,
        biography: biography.present ? biography.value : this.biography,
        preferences: preferences.present ? preferences.value : this.preferences,
        profilePicture:
            profilePicture.present ? profilePicture.value : this.profilePicture,
      );
  @override
  String toString() {
    return (StringBuffer('PopularUser(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('biography: $biography, ')
          ..write('preferences: $preferences, ')
          ..write('profilePicture: $profilePicture')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, biography, preferences,
      i0.$driftBlobEquality.hash(profilePicture));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.PopularUser &&
          other.id == this.id &&
          other.name == this.name &&
          other.biography == this.biography &&
          other.preferences == this.preferences &&
          i0.$driftBlobEquality
              .equals(other.profilePicture, this.profilePicture));
}

class PopularUsers extends i0.View
    with i0.ResultSet<i1.PopularUser, i1.PopularUsers>
    implements i0.GeneratedView<i1.PopularUser, i1.PopularUsers> {
  @override
  final String? alias;
  final i0.GeneratedDatabase _attachedDatabase;
  PopularUsers(this._attachedDatabase, [this.alias]);
  @override
  i0.BaseSelectStatement as() => throw UnimplementedError();
  @override
  List<i0.SchemaColumn> get columns =>
      [id, name, biography, preferences, profilePicture];
  @override
  String get entityName => 'popular_users';
  @override
  PopularUsers asSelfType() => this;

  @override
  i1.PopularUser? Function(i0.DriftRow) createMapperFromPositions(
      List<i0.ColumnPosition> positions) {
    return (i0.DriftRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return i1.PopularUser(
        id: row.readWithType(positions[0], i0.BuiltinDriftType.int)!,
        name: row.readWithType(positions[1], i0.BuiltinDriftType.text)!,
        biography: row.readWithType(positions[2], i0.BuiltinDriftType.text),
        preferences: i1.Users.$converterpreferencesn
            .fromSql(row.readWithType(positions[3], i0.BuiltinDriftType.text)),
        profilePicture:
            row.readWithType(positions[4], i0.BuiltinDriftType.byteArray),
      );
    };
  }

  late final i0.ViewColumn<int> id = i0.ViewColumn<int>.forDriftFile(
      name: 'id', type: i0.BuiltinDriftType.int, isNullable: false)
    ..owningResultSet = this;
  late final i0.ViewColumn<String> name = i0.ViewColumn<String>.forDriftFile(
      name: 'name', type: i0.BuiltinDriftType.text, isNullable: false)
    ..owningResultSet = this;
  late final i0.ViewColumn<String> biography =
      i0.ViewColumn<String>.forDriftFile(
          name: 'biography', type: i0.BuiltinDriftType.text, isNullable: true)
        ..owningResultSet = this;
  late final i0.ViewColumnWithTypeConverter<i2.Preferences?, String>
      preferences = i0.ViewColumn<String>.forDriftFile(
              name: 'preferences',
              type: i0.BuiltinDriftType.text,
              isNullable: true)
          .withConverter<i2.Preferences?>(i1.Users.$converterpreferencesn)
        ..owningResultSet = this;
  late final i0.ViewColumn<i3.Uint8List> profilePicture =
      i0.ViewColumn<i3.Uint8List>.forDriftFile(
          name: 'profile_picture',
          type: i0.BuiltinDriftType.byteArray,
          isNullable: true)
        ..owningResultSet = this;
  @override
  PopularUsers withAlias(String alias) {
    return PopularUsers(_attachedDatabase, alias);
  }

  @override
  i0.SelectStatement? get query => null;
  @override
  i0.CustomComponent get sqlDefinition => i0.CustomComponent(
      'CREATE VIEW popular_users AS SELECT * FROM users ORDER BY (SELECT count(*) FROM follows WHERE followed = users.id)');
  @override
  Set<String> get readsFrom => const {'users', 'follows'};
}
