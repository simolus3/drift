// ignore_for_file: type=lint, invalid_use_of_internal_member
import 'package:drift/drift.dart' as i0;
import 'package:shared/src/users.drift.dart' as i1;
import 'package:shared/src/users.dart' as i2;

class $UsersTable extends i2.Users with i0.TableInfo<$UsersTable, i1.User> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  @override
  late final i0.GeneratedColumn<int> id = i0.GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          i0.GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const i0.VerificationMeta _nameMeta =
      const i0.VerificationMeta('name');
  @override
  late final i0.GeneratedColumn<String> name = i0.GeneratedColumn<String>(
      'name', aliasedName, false,
      type: i0.DriftSqlType.string, requiredDuringInsert: true);
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
      id: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}name'])!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends i0.DataClass implements i0.Insertable<i1.User> {
  final int id;
  final String name;
  const User({required this.id, required this.name});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['name'] = i0.Variable<String>(name);
    return map;
  }

  i1.UsersCompanion toCompanion(bool nullToAbsent) {
    return i1.UsersCompanion(
      id: i0.Value(id),
      name: i0.Value(name),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  i1.User copyWith({int? id, String? name}) => i1.User(
        id: id ?? this.id,
        name: name ?? this.name,
      );
  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.User && other.id == this.id && other.name == this.name);
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

  i1.UsersCompanion copyWith({i0.Value<int>? id, i0.Value<String>? name}) {
    return i1.UsersCompanion(
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

class $$UsersTableFilterComposer
    extends i0.FilterComposer<i0.GeneratedDatabase, i1.$UsersTable> {
  $$UsersTableFilterComposer(super.$db, super.$table, {super.$joinBuilder});
  i0.ColumnFilters<int> get id => $columnFilter($table.id);
  i0.ColumnFilters<String> get name => $columnFilter($table.name);
}

class $$UsersTableOrderingComposer
    extends i0.OrderingComposer<i0.GeneratedDatabase, i1.$UsersTable> {
  $$UsersTableOrderingComposer(super.$db, super.$table, {super.$joinBuilder});
  i0.ColumnOrderings<int> get id => $columnOrdering($table.id);
  i0.ColumnOrderings<String> get name => $columnOrdering($table.name);
}

class $$UsersTableProcessedTableManager extends i0.ProcessedTableManager<
    i0.GeneratedDatabase,
    i1.$UsersTable,
    i1.User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableProcessedTableManager,
    $$UsersTableInsertCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder> {
  const $$UsersTableProcessedTableManager(super.$state);
}

typedef $$UsersTableInsertCompanionBuilder = i1.UsersCompanion Function({
  i0.Value<int> id,
  required String name,
});
typedef $$UsersTableUpdateCompanionBuilder = i1.UsersCompanion Function({
  i0.Value<int> id,
  i0.Value<String> name,
});

class $$UsersTableTableManager extends i0.RootTableManager<
    i0.GeneratedDatabase,
    i1.$UsersTable,
    i1.User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableProcessedTableManager,
    $$UsersTableInsertCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder> {
  $$UsersTableTableManager(i0.GeneratedDatabase db, i1.$UsersTable table)
      : super(i0.TableManagerState(
            db: db,
            table: table,
            filteringComposer: $$UsersTableFilterComposer(db, table),
            orderingComposer: $$UsersTableOrderingComposer(db, table),
            getChildManagerBuilder: (p0) =>
                $$UsersTableProcessedTableManager(p0),
            getUpdateCompanionBuilder: ({
              i0.Value<int> id = const i0.Value.absent(),
              i0.Value<String> name = const i0.Value.absent(),
            }) =>
                i1.UsersCompanion(
                  id: id,
                  name: name,
                ),
            getInsertCompanionBuilder: ({
              i0.Value<int> id = const i0.Value.absent(),
              required String name,
            }) =>
                i1.UsersCompanion.insert(
                  id: id,
                  name: name,
                )));
}
