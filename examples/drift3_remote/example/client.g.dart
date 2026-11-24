// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client.dart';

// ignore_for_file: type=lint
class $MessagesTable extends Messages
    with ResultSet<Message, $MessagesTable>
    implements GeneratedTable<Message, $MessagesTable> {
  @override
  final String? alias;
  $MessagesTable([this.alias]);
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
  late final TableColumn<String> content = TableColumn<String>(
    name: 'content',
    sqlType: SqlType.text,
    requiredDuringInsert: true,
    constraints: () => [const ColumnNotNullConstraint()],
  )..owningResultSet = this;
  @override
  List<TableColumn> get columns => [id, content];
  @override
  String get entityName => $name;
  static const String $name = 'messages';
  @override
  $MessagesTable asSelfType() => this;

  @override
  Set<TableColumn> get resolvedPrimaryKey => {id};
  @override
  Message? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$id = positions[0].index;
    final type$0 = dialect.intType;
    final pos$content = positions[1].index;
    final type$1 = dialect.textType;
    return (RawRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row[pos$id] == null) {
        return null;
      }
      return Message(
        id: type$0.dartValue(row[pos$id]!),
        content: type$1.dartValue(row[pos$content]!),
      );
    };
  }

  @override
  $MessagesTable withAlias(String alias) {
    return $MessagesTable(alias);
  }

  @override
  List<TableConstraint> get tableConstraints => [];
}

class Message extends LegacyDataClass implements Insertable<Message> {
  final int id;
  final String content;
  const Message({required this.id, required this.content});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id, SqlType.int);
    map['content'] = Variable<String>(content, SqlType.text);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(id: Value(id), content: Value(content));
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<int>(json['id']),
      content: serializer.fromJson<String>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'content': serializer.toJson<String>(content),
    };
  }

  Message copyWith({int? id, String? content}) =>
      Message(id: id ?? this.id, content: content ?? this.content);
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, content);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.content == this.content);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<int> id;
  final Value<String> content;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
  });
  MessagesCompanion.insert({
    this.id = const Value.absent(),
    required String content,
  }) : content = Value(content);
  static Insertable<Message> custom({
    Expression<int>? id,
    Expression<String>? content,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
    });
  }

  MessagesCompanion copyWith({Value<int>? id, Value<String>? content}) {
    return MessagesCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value, SqlType.int);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value, SqlType.text);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }
}

abstract base class _$ChatDatabase extends GeneratedDatabase {
  _$ChatDatabase(super.implementation);
  $MessagesTable get messages => $MessagesTable();
  TableOrViewStatements<Message, $MessagesTable> get messagesQueries =>
      this.messages.statements(this);
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
  static final DatabaseSchema _$schema = DatabaseSchema([$MessagesTable()]);
}
