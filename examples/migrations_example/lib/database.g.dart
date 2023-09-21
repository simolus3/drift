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
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('name'));
  static const VerificationMeta _birthdayMeta =
      const VerificationMeta('birthday');
  @override
  late final GeneratedColumn<DateTime> birthday = GeneratedColumn<DateTime>(
      'birthday', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _nextUserMeta =
      const VerificationMeta('nextUser');
  @override
  late final GeneratedColumn<int> nextUser = GeneratedColumn<int>(
      'next_user', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  @override
  List<GeneratedColumn> get $columns => [id, name, birthday, nextUser];
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
    }
    if (data.containsKey('birthday')) {
      context.handle(_birthdayMeta,
          birthday.isAcceptableOrUnknown(data['birthday']!, _birthdayMeta));
    }
    if (data.containsKey('next_user')) {
      context.handle(_nextUserMeta,
          nextUser.isAcceptableOrUnknown(data['next_user']!, _nextUserMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {name, birthday},
      ];
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      birthday: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}birthday']),
      nextUser: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}next_user']),
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final int id;
  final String name;
  final DateTime? birthday;
  final int? nextUser;
  const User(
      {required this.id, required this.name, this.birthday, this.nextUser});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || birthday != null) {
      map['birthday'] = Variable<DateTime>(birthday);
    }
    if (!nullToAbsent || nextUser != null) {
      map['next_user'] = Variable<int>(nextUser);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      birthday: birthday == null && nullToAbsent
          ? const Value.absent()
          : Value(birthday),
      nextUser: nextUser == null && nullToAbsent
          ? const Value.absent()
          : Value(nextUser),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      birthday: serializer.fromJson<DateTime?>(json['birthday']),
      nextUser: serializer.fromJson<int?>(json['nextUser']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'birthday': serializer.toJson<DateTime?>(birthday),
      'nextUser': serializer.toJson<int?>(nextUser),
    };
  }

  User copyWith(
          {int? id,
          String? name,
          Value<DateTime?> birthday = const Value.absent(),
          Value<int?> nextUser = const Value.absent()}) =>
      User(
        id: id ?? this.id,
        name: name ?? this.name,
        birthday: birthday.present ? birthday.value : this.birthday,
        nextUser: nextUser.present ? nextUser.value : this.nextUser,
      );
  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('birthday: $birthday, ')
          ..write('nextUser: $nextUser')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, birthday, nextUser);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.name == this.name &&
          other.birthday == this.birthday &&
          other.nextUser == this.nextUser);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime?> birthday;
  final Value<int?> nextUser;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.birthday = const Value.absent(),
    this.nextUser = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.birthday = const Value.absent(),
    this.nextUser = const Value.absent(),
  });
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? birthday,
    Expression<int>? nextUser,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (birthday != null) 'birthday': birthday,
      if (nextUser != null) 'next_user': nextUser,
    });
  }

  UsersCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<DateTime?>? birthday,
      Value<int?>? nextUser}) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      birthday: birthday ?? this.birthday,
      nextUser: nextUser ?? this.nextUser,
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
    if (birthday.present) {
      map['birthday'] = Variable<DateTime>(birthday.value);
    }
    if (nextUser.present) {
      map['next_user'] = Variable<int>(nextUser.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('birthday: $birthday, ')
          ..write('nextUser: $nextUser')
          ..write(')'))
        .toString();
  }
}

class Groups extends Table with TableInfo<Groups, Group> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Groups(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _deletedMeta =
      const VerificationMeta('deleted');
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      $customConstraints: 'DEFAULT FALSE',
      defaultValue: const CustomExpression('FALSE'));
  static const VerificationMeta _ownerMeta = const VerificationMeta('owner');
  late final GeneratedColumn<int> owner = GeneratedColumn<int>(
      'owner', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL REFERENCES users(id)');
  @override
  List<GeneratedColumn> get $columns => [id, title, deleted, owner];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'groups';
  @override
  VerificationContext validateIntegrity(Insertable<Group> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta,
          deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('owner')) {
      context.handle(
          _ownerMeta, owner.isAcceptableOrUnknown(data['owner']!, _ownerMeta));
    } else if (isInserting) {
      context.missing(_ownerMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Group map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Group(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted']),
      owner: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}owner'])!,
    );
  }

  @override
  Groups createAlias(String alias) {
    return Groups(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(id)'];
  @override
  bool get dontWriteConstraints => true;
}

class Group extends DataClass implements Insertable<Group> {
  final int id;
  final String title;
  final bool? deleted;
  final int owner;
  const Group(
      {required this.id,
      required this.title,
      this.deleted,
      required this.owner});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || deleted != null) {
      map['deleted'] = Variable<bool>(deleted);
    }
    map['owner'] = Variable<int>(owner);
    return map;
  }

  GroupsCompanion toCompanion(bool nullToAbsent) {
    return GroupsCompanion(
      id: Value(id),
      title: Value(title),
      deleted: deleted == null && nullToAbsent
          ? const Value.absent()
          : Value(deleted),
      owner: Value(owner),
    );
  }

  factory Group.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Group(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      deleted: serializer.fromJson<bool?>(json['deleted']),
      owner: serializer.fromJson<int>(json['owner']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'deleted': serializer.toJson<bool?>(deleted),
      'owner': serializer.toJson<int>(owner),
    };
  }

  Group copyWith(
          {int? id,
          String? title,
          Value<bool?> deleted = const Value.absent(),
          int? owner}) =>
      Group(
        id: id ?? this.id,
        title: title ?? this.title,
        deleted: deleted.present ? deleted.value : this.deleted,
        owner: owner ?? this.owner,
      );
  @override
  String toString() {
    return (StringBuffer('Group(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('deleted: $deleted, ')
          ..write('owner: $owner')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, deleted, owner);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Group &&
          other.id == this.id &&
          other.title == this.title &&
          other.deleted == this.deleted &&
          other.owner == this.owner);
}

class GroupsCompanion extends UpdateCompanion<Group> {
  final Value<int> id;
  final Value<String> title;
  final Value<bool?> deleted;
  final Value<int> owner;
  const GroupsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.deleted = const Value.absent(),
    this.owner = const Value.absent(),
  });
  GroupsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.deleted = const Value.absent(),
    required int owner,
  })  : title = Value(title),
        owner = Value(owner);
  static Insertable<Group> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<bool>? deleted,
    Expression<int>? owner,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (deleted != null) 'deleted': deleted,
      if (owner != null) 'owner': owner,
    });
  }

  GroupsCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<bool?>? deleted,
      Value<int>? owner}) {
    return GroupsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      deleted: deleted ?? this.deleted,
      owner: owner ?? this.owner,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (owner.present) {
      map['owner'] = Variable<int>(owner.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('deleted: $deleted, ')
          ..write('owner: $owner')
          ..write(')'))
        .toString();
  }
}

class Notes extends Table
    with TableInfo<Notes, Note>, VirtualTableInfo<Notes, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Notes(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: '');
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: '');
  static const VerificationMeta _searchTermsMeta =
      const VerificationMeta('searchTerms');
  late final GeneratedColumn<String> searchTerms = GeneratedColumn<String>(
      'search_terms', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns => [title, content, searchTerms];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(Insertable<Note> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('search_terms')) {
      context.handle(
          _searchTermsMeta,
          searchTerms.isAcceptableOrUnknown(
              data['search_terms']!, _searchTermsMeta));
    } else if (isInserting) {
      context.missing(_searchTermsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      searchTerms: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}search_terms'])!,
    );
  }

  @override
  Notes createAlias(String alias) {
    return Notes(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs =>
      'fts5(title, content, search_terms, tokenize = "unicode61 tokenchars \'.\'")';
}

class Note extends DataClass implements Insertable<Note> {
  final String title;
  final String content;
  final String searchTerms;
  const Note(
      {required this.title, required this.content, required this.searchTerms});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    map['search_terms'] = Variable<String>(searchTerms);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      title: Value(title),
      content: Value(content),
      searchTerms: Value(searchTerms),
    );
  }

  factory Note.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      searchTerms: serializer.fromJson<String>(json['search_terms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'search_terms': serializer.toJson<String>(searchTerms),
    };
  }

  Note copyWith({String? title, String? content, String? searchTerms}) => Note(
        title: title ?? this.title,
        content: content ?? this.content,
        searchTerms: searchTerms ?? this.searchTerms,
      );
  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('searchTerms: $searchTerms')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(title, content, searchTerms);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.title == this.title &&
          other.content == this.content &&
          other.searchTerms == this.searchTerms);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<String> title;
  final Value<String> content;
  final Value<String> searchTerms;
  final Value<int> rowid;
  const NotesCompanion({
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.searchTerms = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    required String title,
    required String content,
    required String searchTerms,
    this.rowid = const Value.absent(),
  })  : title = Value(title),
        content = Value(content),
        searchTerms = Value(searchTerms);
  static Insertable<Note> custom({
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? searchTerms,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (searchTerms != null) 'search_terms': searchTerms,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith(
      {Value<String>? title,
      Value<String>? content,
      Value<String>? searchTerms,
      Value<int>? rowid}) {
    return NotesCompanion(
      title: title ?? this.title,
      content: content ?? this.content,
      searchTerms: searchTerms ?? this.searchTerms,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (searchTerms.present) {
      map['search_terms'] = Variable<String>(searchTerms.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('searchTerms: $searchTerms, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class GroupCountData extends DataClass {
  final int id;
  final String name;
  final DateTime? birthday;
  final int? nextUser;
  final int groupCount;
  const GroupCountData(
      {required this.id,
      required this.name,
      this.birthday,
      this.nextUser,
      required this.groupCount});
  factory GroupCountData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupCountData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      birthday: serializer.fromJson<DateTime?>(json['birthday']),
      nextUser: serializer.fromJson<int?>(json['next_user']),
      groupCount: serializer.fromJson<int>(json['group_count']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'birthday': serializer.toJson<DateTime?>(birthday),
      'next_user': serializer.toJson<int?>(nextUser),
      'group_count': serializer.toJson<int>(groupCount),
    };
  }

  GroupCountData copyWith(
          {int? id,
          String? name,
          Value<DateTime?> birthday = const Value.absent(),
          Value<int?> nextUser = const Value.absent(),
          int? groupCount}) =>
      GroupCountData(
        id: id ?? this.id,
        name: name ?? this.name,
        birthday: birthday.present ? birthday.value : this.birthday,
        nextUser: nextUser.present ? nextUser.value : this.nextUser,
        groupCount: groupCount ?? this.groupCount,
      );
  @override
  String toString() {
    return (StringBuffer('GroupCountData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('birthday: $birthday, ')
          ..write('nextUser: $nextUser, ')
          ..write('groupCount: $groupCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, birthday, nextUser, groupCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupCountData &&
          other.id == this.id &&
          other.name == this.name &&
          other.birthday == this.birthday &&
          other.nextUser == this.nextUser &&
          other.groupCount == this.groupCount);
}

class GroupCount extends ViewInfo<GroupCount, GroupCountData>
    implements HasResultSet {
  final String? _alias;
  @override
  final _$Database attachedDatabase;
  GroupCount(this.attachedDatabase, [this._alias]);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, birthday, nextUser, groupCount];
  @override
  String get aliasedName => _alias ?? entityName;
  @override
  String get entityName => 'group_count';
  @override
  Map<SqlDialect, String> get createViewStatements => {
        SqlDialect.sqlite:
            'CREATE VIEW group_count AS SELECT users.*, (SELECT COUNT(*) FROM "groups" WHERE owner = users.id) AS group_count FROM users',
      };
  @override
  GroupCount get asDslTable => this;
  @override
  GroupCountData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupCountData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      birthday: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}birthday']),
      nextUser: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}next_user']),
      groupCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}group_count'])!,
    );
  }

  late final GeneratedColumn<int> id =
      GeneratedColumn<int>('id', aliasedName, false, type: DriftSqlType.int);
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string);
  late final GeneratedColumn<DateTime> birthday = GeneratedColumn<DateTime>(
      'birthday', aliasedName, true,
      type: DriftSqlType.dateTime);
  late final GeneratedColumn<int> nextUser = GeneratedColumn<int>(
      'next_user', aliasedName, true,
      type: DriftSqlType.int);
  late final GeneratedColumn<int> groupCount = GeneratedColumn<int>(
      'group_count', aliasedName, false,
      type: DriftSqlType.int);
  @override
  GroupCount createAlias(String alias) {
    return GroupCount(attachedDatabase, alias);
  }

  @override
  Query? get query => null;
  @override
  Set<String> get readTables => const {'users', 'groups'};
}

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(e);
  late final $UsersTable users = $UsersTable(this);
  late final Groups groups = Groups(this);
  late final Notes notes = Notes(this);
  late final GroupCount groupCount = GroupCount(this);
  late final Index userName =
      Index('user_name', 'CREATE INDEX user_name ON users (name)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [users, groups, notes, groupCount, userName];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}
