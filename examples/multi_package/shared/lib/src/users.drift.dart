// dart format width=80
// ignore_for_file: type=lint
import 'package:drift3_preview/drift.dart' as i0;
import 'package:shared/src/users.drift.dart' as i1;
import 'package:shared/src/users.dart' as i2;

class $UsersTable extends i2.Users
    with i0.ResultSet<i1.User, $UsersTable>
    implements i0.GeneratedTable<i1.User, $UsersTable> {
  @override
  final String? alias;
  $UsersTable([this.alias]);
  @override
  late final i0.TableColumn<int> id = i0.TableColumn<int>(
      name: 'id',
      sqlType: i0.SqlType.int,
      requiredDuringInsert: false,
      constraints: () => [
            const i0.ColumnPrimaryKeyConstraint(isAutoIncrementing: true),
            const i0.ColumnNotNullConstraint()
          ])
    ..owningResultSet = this;
  @override
  late final i0.TableColumn<String> name = i0.TableColumn<String>(
      name: 'name',
      sqlType: i0.SqlType.text,
      requiredDuringInsert: true,
      constraints: () => [const i0.ColumnNotNullConstraint()])
    ..owningResultSet = this;
  @override
  List<i0.TableColumn> get columns => [id, name];
  @override
  String get entityName => $name;
  static const String $name = 'users';
  @override
  $UsersTable asSelfType() => this;

  @override
  i1.User? Function(i0.RawRow) createMapperFromPositions(
      i0.DriftDialect dialect, List<i0.ColumnPosition> positions) {
    final pos$id = positions[0].index;
    final type$0 = i0.SqlType.int.resolveIn(dialect);
    final pos$name = positions[1].index;
    final type$1 = i0.SqlType.text.resolveIn(dialect);
    return (i0.RawRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row[pos$id] == null) {
        return null;
      }
      return i1.User(
        id: type$0.dartValue(row[pos$id]!),
        name: type$1.dartValue(row[pos$name]!),
      );
    };
  }

  @override
  $UsersTable withAlias(String alias) {
    return $UsersTable(alias);
  }
}

class User extends i0.LegacyDataClass implements i0.Insertable<i1.User> {
  final int id;
  final String name;
  const User({required this.id, required this.name});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id, i0.SqlType.int);
    map['name'] = i0.Variable<String>(name, i0.SqlType.text);
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
  User copyWithCompanion(i1.UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

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
      map['id'] = i0.Variable<int>(id.value, i0.SqlType.int);
    }
    if (name.present) {
      map['name'] = i0.Variable<String>(name.value, i0.SqlType.text);
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
