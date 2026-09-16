// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// ignore_for_file: type=lint
class $NotesTable extends Notes
    with ResultSet<Note, $NotesTable>
    implements GeneratedTable<Note, $NotesTable> {
  @override
  final String? alias;
  $NotesTable([this.alias]);
  @override
  late final TableColumn<int> id = TableColumn<int>(
    name: 'id',
    sqlType: SqlType.int,
    requiredDuringInsert: false,
    constraints: () => [
      const ColumnPrimaryKeyConstraint(isAutoIncrementing: true),
      const ColumnNotNullConstraint(),
    ],
  )..owningResultSet = this;
  @override
  late final TableColumn<String> contents = TableColumn<String>(
    name: 'contents',
    sqlType: SqlType.text,
    requiredDuringInsert: true,
    constraints: () => [const ColumnNotNullConstraint()],
  )..owningResultSet = this;
  @override
  List<TableColumn> get columns => [id, contents];
  @override
  String get entityName => $name;
  static const String $name = 'notes';
  @override
  $NotesTable asSelfType() => this;

  @override
  Note? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$id = positions[0].index;
    final type$0 = SqlType.int.resolveIn(dialect);
    final pos$contents = positions[1].index;
    final type$1 = SqlType.text.resolveIn(dialect);
    return (RawRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row[pos$id] == null) {
        return null;
      }
      return Note(
        id: type$0.dartValue(row[pos$id]!),
        contents: type$1.dartValue(row[pos$contents]!),
      );
    };
  }

  @override
  $NotesTable withAlias(String alias) {
    return $NotesTable(alias);
  }
}

class Note extends LegacyDataClass implements Insertable<Note> {
  final int id;
  final String contents;
  const Note({required this.id, required this.contents});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id, SqlType.int);
    map['contents'] = Variable<String>(contents, SqlType.text);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(id: Value(id), contents: Value(contents));
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<int>(json['id']),
      contents: serializer.fromJson<String>(json['contents']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'contents': serializer.toJson<String>(contents),
    };
  }

  Note copyWith({int? id, String? contents}) =>
      Note(id: id ?? this.id, contents: contents ?? this.contents);
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      contents: data.contents.present ? data.contents.value : this.contents,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('contents: $contents')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, contents);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note && other.id == this.id && other.contents == this.contents);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<int> id;
  final Value<String> contents;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.contents = const Value.absent(),
  });
  NotesCompanion.insert({
    this.id = const Value.absent(),
    required String contents,
  }) : contents = Value(contents);
  static Insertable<Note> custom({
    Expression<int>? id,
    Expression<String>? contents,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contents != null) 'contents': contents,
    });
  }

  NotesCompanion copyWith({Value<int>? id, Value<String>? contents}) {
    return NotesCompanion(
      id: id ?? this.id,
      contents: contents ?? this.contents,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value, SqlType.int);
    }
    if (contents.present) {
      map['contents'] = Variable<String>(contents.value, SqlType.text);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('contents: $contents')
          ..write(')'))
        .toString();
  }
}

abstract base class _$ExampleDatabase extends GeneratedDatabase {
  _$ExampleDatabase(super.implementation);
  $NotesTable get notes => $NotesTable();
  TableOrViewStatements<Note, $NotesTable> get notesQueries =>
      this.notes.statements(this);
  @override
  Map<KnownSqlDialect, Object> get dialectOptions => {
    KnownSqlDialect.sqlite: const SqliteOptions(
      strictTablesByDefault: true,
      storeDateTimesAsText: true,
      useBinaryJsonRepresentation: true,
    ),
  };
  @override
  DatabaseSchema get schema => _$schema;
  static final DatabaseSchema _$schema = DatabaseSchema([$NotesTable()]);
}
