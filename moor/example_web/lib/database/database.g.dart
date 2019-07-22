// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps
class Entry extends DataClass implements Insertable<Entry> {
  final int id;
  final String content;
  final bool done;
  Entry({@required this.id, @required this.content, @required this.done});
  factory Entry.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    final boolType = db.typeSystem.forDartType<bool>();
    return Entry(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}id']),
      content:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}content']),
      done: boolType.mapFromDatabaseResponse(data['${effectivePrefix}done']),
    );
  }
  factory Entry.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return Entry(
      id: serializer.fromJson<int>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      done: serializer.fromJson<bool>(json['done']),
    );
  }
  @override
  Map<String, dynamic> toJson(
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return {
      'id': serializer.toJson<int>(id),
      'content': serializer.toJson<String>(content),
      'done': serializer.toJson<bool>(done),
    };
  }

  @override
  T createCompanion<T extends UpdateCompanion<Entry>>(bool nullToAbsent) {
    return TodoEntriesCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      done: done == null && nullToAbsent ? const Value.absent() : Value(done),
    ) as T;
  }

  Entry copyWith({int id, String content, bool done}) => Entry(
        id: id ?? this.id,
        content: content ?? this.content,
        done: done ?? this.done,
      );
  @override
  String toString() {
    return (StringBuffer('Entry(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('done: $done')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      $mrjf($mrjc(id.hashCode, $mrjc(content.hashCode, done.hashCode)));
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is Entry &&
          other.id == id &&
          other.content == content &&
          other.done == done);
}

class TodoEntriesCompanion extends UpdateCompanion<Entry> {
  final Value<int> id;
  final Value<String> content;
  final Value<bool> done;
  const TodoEntriesCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.done = const Value.absent(),
  });
}

class $TodoEntriesTable extends TodoEntries
    with TableInfo<$TodoEntriesTable, Entry> {
  final GeneratedDatabase _db;
  final String _alias;
  $TodoEntriesTable(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  GeneratedIntColumn _id;
  @override
  GeneratedIntColumn get id => _id ??= _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false, hasAutoIncrement: true);
  }

  final VerificationMeta _contentMeta = const VerificationMeta('content');
  GeneratedTextColumn _content;
  @override
  GeneratedTextColumn get content => _content ??= _constructContent();
  GeneratedTextColumn _constructContent() {
    return GeneratedTextColumn(
      'content',
      $tableName,
      false,
    );
  }

  final VerificationMeta _doneMeta = const VerificationMeta('done');
  GeneratedBoolColumn _done;
  @override
  GeneratedBoolColumn get done => _done ??= _constructDone();
  GeneratedBoolColumn _constructDone() {
    return GeneratedBoolColumn('done', $tableName, false,
        defaultValue: const Constant(false));
  }

  @override
  List<GeneratedColumn> get $columns => [id, content, done];
  @override
  $TodoEntriesTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'todo_entries';
  @override
  final String actualTableName = 'todo_entries';
  @override
  VerificationContext validateIntegrity(TodoEntriesCompanion d,
      {bool isInserting = false}) {
    final context = VerificationContext();
    if (d.id.present) {
      context.handle(_idMeta, id.isAcceptableValue(d.id.value, _idMeta));
    } else if (id.isRequired && isInserting) {
      context.missing(_idMeta);
    }
    if (d.content.present) {
      context.handle(_contentMeta,
          content.isAcceptableValue(d.content.value, _contentMeta));
    } else if (content.isRequired && isInserting) {
      context.missing(_contentMeta);
    }
    if (d.done.present) {
      context.handle(
          _doneMeta, done.isAcceptableValue(d.done.value, _doneMeta));
    } else if (done.isRequired && isInserting) {
      context.missing(_doneMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Entry map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Entry.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Map<String, Variable> entityToSql(TodoEntriesCompanion d) {
    final map = <String, Variable>{};
    if (d.id.present) {
      map['id'] = Variable<int, IntType>(d.id.value);
    }
    if (d.content.present) {
      map['content'] = Variable<String, StringType>(d.content.value);
    }
    if (d.done.present) {
      map['done'] = Variable<bool, BoolType>(d.done.value);
    }
    return map;
  }

  @override
  $TodoEntriesTable createAlias(String alias) {
    return $TodoEntriesTable(_db, alias);
  }
}

class HiddenEntryCountResult {
  final int entries;
  HiddenEntryCountResult({
    this.entries,
  });
}

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(const SqlTypeSystem.withDefaults(), e);
  $TodoEntriesTable _todoEntries;
  $TodoEntriesTable get todoEntries => _todoEntries ??= $TodoEntriesTable(this);
  HiddenEntryCountResult _rowToHiddenEntryCountResult(QueryRow row) {
    return HiddenEntryCountResult(
      entries: row.readInt('entries'),
    );
  }

  Future<List<HiddenEntryCountResult>> hiddenEntryCount(
      {@Deprecated('No longer needed with Moor 1.6 - see the changelog for details')
          QueryEngine operateOn}) {
    return (operateOn ?? this).customSelect(
        'SELECT COUNT(*) - 20 AS entries FROM todo_entries WHERE done',
        variables: []).then((rows) => rows.map(_rowToHiddenEntryCountResult).toList());
  }

  Stream<List<HiddenEntryCountResult>> watchHiddenEntryCount() {
    return customSelectStream(
            'SELECT COUNT(*) - 20 AS entries FROM todo_entries WHERE done',
            variables: [],
            readsFrom: {todoEntries})
        .map((rows) => rows.map(_rowToHiddenEntryCountResult).toList());
  }

  @override
  List<TableInfo> get allTables => [todoEntries];
}
