// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:modular/src/users.drift.dart' as i1;
import 'package:drift/internal/modular.dart' as i2;

class User extends i0.DataClass implements i0.Insertable<i1.User> {
  final int id;
  final String name;
  final String? biography;
  const User({required this.id, required this.name, this.biography});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['name'] = i0.Variable<String>(name);
    if (!nullToAbsent || biography != null) {
      map['biography'] = i0.Variable<String>(biography);
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
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      biography: serializer.fromJson<String?>(json['biography']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'biography': serializer.toJson<String?>(biography),
    };
  }

  i1.User copyWith(
          {int? id,
          String? name,
          i0.Value<String?> biography = const i0.Value.absent()}) =>
      i1.User(
        id: id ?? this.id,
        name: name ?? this.name,
        biography: biography.present ? biography.value : this.biography,
      );
  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('biography: $biography')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, biography);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.User &&
          other.id == this.id &&
          other.name == this.name &&
          other.biography == this.biography);
}

class UsersCompanion extends i0.UpdateCompanion<i1.User> {
  final i0.Value<int> id;
  final i0.Value<String> name;
  final i0.Value<String?> biography;
  const UsersCompanion({
    this.id = const i0.Value.absent(),
    this.name = const i0.Value.absent(),
    this.biography = const i0.Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const i0.Value.absent(),
    required String name,
    this.biography = const i0.Value.absent(),
  }) : name = i0.Value(name);
  static i0.Insertable<i1.User> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? name,
    i0.Expression<String>? biography,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (biography != null) 'biography': biography,
    });
  }

  i1.UsersCompanion copyWith(
      {i0.Value<int>? id,
      i0.Value<String>? name,
      i0.Value<String?>? biography}) {
    return i1.UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      biography: biography ?? this.biography,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('i1.UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('biography: $biography')
          ..write(')'))
        .toString();
  }
}

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
  static const i0.VerificationMeta _biographyMeta =
      const i0.VerificationMeta('biography');
  late final i0.GeneratedColumn<String> biography = i0.GeneratedColumn<String>(
      'biography', aliasedName, true,
      type: i0.DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  @override
  List<i0.GeneratedColumn> get $columns => [id, name, biography];
  @override
  String get aliasedName => _alias ?? 'users';
  @override
  String get actualTableName => 'users';
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
    if (data.containsKey('biography')) {
      context.handle(_biographyMeta,
          biography.isAcceptableOrUnknown(data['biography']!, _biographyMeta));
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.User(
      id: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}name'])!,
      biography: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}biography']),
    );
  }

  @override
  Users createAlias(String alias) {
    return Users(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [];
  @override
  bool get dontWriteConstraints => true;
}

i0.Index get usersName =>
    i0.Index('users_name', 'CREATE INDEX users_name ON users (name)');

class Follow extends i0.DataClass implements i0.Insertable<i1.Follow> {
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
  const FollowsCompanion({
    this.followed = const i0.Value.absent(),
    this.follower = const i0.Value.absent(),
  });
  FollowsCompanion.insert({
    required int followed,
    required int follower,
  })  : followed = i0.Value(followed),
        follower = i0.Value(follower);
  static i0.Insertable<i1.Follow> custom({
    i0.Expression<int>? followed,
    i0.Expression<int>? follower,
  }) {
    return i0.RawValuesInsertable({
      if (followed != null) 'followed': followed,
      if (follower != null) 'follower': follower,
    });
  }

  i1.FollowsCompanion copyWith(
      {i0.Value<int>? followed, i0.Value<int>? follower}) {
    return i1.FollowsCompanion(
      followed: followed ?? this.followed,
      follower: follower ?? this.follower,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('i1.FollowsCompanion(')
          ..write('followed: $followed, ')
          ..write('follower: $follower')
          ..write(')'))
        .toString();
  }
}

class Follows extends i0.Table with i0.TableInfo<Follows, i1.Follow> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  Follows(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _followedMeta =
      const i0.VerificationMeta('followed');
  late final i0.GeneratedColumn<int> followed = i0.GeneratedColumn<int>(
      'followed', aliasedName, false,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL REFERENCES users(id)');
  static const i0.VerificationMeta _followerMeta =
      const i0.VerificationMeta('follower');
  late final i0.GeneratedColumn<int> follower = i0.GeneratedColumn<int>(
      'follower', aliasedName, false,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL REFERENCES users(id)');
  @override
  List<i0.GeneratedColumn> get $columns => [followed, follower];
  @override
  String get aliasedName => _alias ?? 'follows';
  @override
  String get actualTableName => 'follows';
  @override
  i0.VerificationContext validateIntegrity(i0.Insertable<i1.Follow> instance,
      {bool isInserting = false}) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('followed')) {
      context.handle(_followedMeta,
          followed.isAcceptableOrUnknown(data['followed']!, _followedMeta));
    } else if (isInserting) {
      context.missing(_followedMeta);
    }
    if (data.containsKey('follower')) {
      context.handle(_followerMeta,
          follower.isAcceptableOrUnknown(data['follower']!, _followerMeta));
    } else if (isInserting) {
      context.missing(_followerMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {followed, follower};
  @override
  i1.Follow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.Follow(
      followed: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}followed'])!,
      follower: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}follower'])!,
    );
  }

  @override
  Follows createAlias(String alias) {
    return Follows(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints =>
      const ['PRIMARY KEY(followed, follower)'];
  @override
  bool get dontWriteConstraints => true;
}

class UsersDrift extends i2.ModularAccessor {
  UsersDrift(i0.GeneratedDatabase db) : super(db);
  i0.Selectable<i1.User> findUsers({FindUsers$predicate? predicate}) {
    var $arrayStartIndex = 1;
    final generatedpredicate = $write(
        predicate?.call(this.users) ?? const i0.CustomExpression('(TRUE)'),
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedpredicate.amountOfVariables;
    return customSelect('SELECT * FROM users WHERE ${generatedpredicate.sql}',
        variables: [
          ...generatedpredicate.introducedVariables
        ],
        readsFrom: {
          users,
          ...generatedpredicate.watchedTables,
        }).asyncMap(users.mapFromRow);
  }

  i1.Users get users => this.resultSet<i1.Users>('users');
}

typedef FindUsers$predicate = i0.Expression<bool> Function(Users users);
