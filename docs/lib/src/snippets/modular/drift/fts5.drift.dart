// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:drift_website/src/snippets/modular/drift/fts5.drift.dart' as i1;
import 'package:drift/internal/modular.dart' as i2;

typedef $EmailCreateCompanionBuilder =
    i1.EmailCompanion Function({
      required String sender,
      required String title,
      required String body,
      i0.Value<int> rowid,
    });
typedef $EmailUpdateCompanionBuilder =
    i1.EmailCompanion Function({
      i0.Value<String> sender,
      i0.Value<String> title,
      i0.Value<String> body,
      i0.Value<int> rowid,
    });

class $EmailFilterComposer extends i0.Composer<i0.GeneratedDatabase, i1.Email> {
  $EmailFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $EmailOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.Email> {
  $EmailOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $EmailAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.Email> {
  $EmailAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get sender =>
      $composableBuilder(column: $table.sender, builder: (column) => column);

  i0.GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  i0.GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);
}

class $EmailTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.Email,
          i1.EmailData,
          i1.$EmailFilterComposer,
          i1.$EmailOrderingComposer,
          i1.$EmailAnnotationComposer,
          $EmailCreateCompanionBuilder,
          $EmailUpdateCompanionBuilder,
          (
            i1.EmailData,
            i0.BaseReferences<i0.GeneratedDatabase, i1.Email, i1.EmailData>,
          ),
          i1.EmailData,
          i0.PrefetchHooks Function()
        > {
  $EmailTableManager(i0.GeneratedDatabase db, i1.Email table)
    : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$EmailFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$EmailOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$EmailAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> sender = const i0.Value.absent(),
                i0.Value<String> title = const i0.Value.absent(),
                i0.Value<String> body = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.EmailCompanion(
                sender: sender,
                title: title,
                body: body,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sender,
                required String title,
                required String body,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.EmailCompanion.insert(
                sender: sender,
                title: title,
                body: body,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.Email, i1.EmailData>(table),
                  i0.BaseReferences<
                    i0.GeneratedDatabase,
                    i1.Email,
                    i1.EmailData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $EmailProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.Email,
      i1.EmailData,
      i1.$EmailFilterComposer,
      i1.$EmailOrderingComposer,
      i1.$EmailAnnotationComposer,
      $EmailCreateCompanionBuilder,
      $EmailUpdateCompanionBuilder,
      (
        i1.EmailData,
        i0.BaseReferences<i0.GeneratedDatabase, i1.Email, i1.EmailData>,
      ),
      i1.EmailData,
      i0.PrefetchHooks Function()
    >;

class Email extends i0.Table
    with
        i0.TableInfo<Email, i1.EmailData>,
        i0.VirtualTableInfo<Email, i1.EmailData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  Email(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _senderMeta = const i0.VerificationMeta(
    'sender',
  );
  late final i0.GeneratedColumn<String> sender = i0.GeneratedColumn<String>(
    'sender',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const i0.VerificationMeta _titleMeta = const i0.VerificationMeta(
    'title',
  );
  late final i0.GeneratedColumn<String> title = i0.GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const i0.VerificationMeta _bodyMeta = const i0.VerificationMeta(
    'body',
  );
  late final i0.GeneratedColumn<String> body = i0.GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  @override
  List<i0.GeneratedColumn> get $columns => [sender, title, body];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'email';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.EmailData> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sender')) {
      context.handle(
        _senderMeta,
        sender.isAcceptableOrUnknown(data['sender']!, _senderMeta),
      );
    } else if (isInserting) {
      context.missing(_senderMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => const {};
  @override
  i1.EmailData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.EmailData(
      sender: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}sender'],
      )!,
      title: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
    );
  }

  @override
  Email createAlias(String alias) {
    return Email(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs => 'fts5(sender, title, body)';
}

class EmailData extends i0.DataClass implements i0.Insertable<i1.EmailData> {
  final String sender;
  final String title;
  final String body;
  const EmailData({
    required this.sender,
    required this.title,
    required this.body,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['sender'] = i0.Variable<String>(sender);
    map['title'] = i0.Variable<String>(title);
    map['body'] = i0.Variable<String>(body);
    return map;
  }

  i1.EmailCompanion toCompanion(bool nullToAbsent) {
    return i1.EmailCompanion(
      sender: i0.Value(sender),
      title: i0.Value(title),
      body: i0.Value(body),
    );
  }

  factory EmailData.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return EmailData(
      sender: serializer.fromJson<String>(json['sender']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sender': serializer.toJson<String>(sender),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
    };
  }

  i1.EmailData copyWith({String? sender, String? title, String? body}) =>
      i1.EmailData(
        sender: sender ?? this.sender,
        title: title ?? this.title,
        body: body ?? this.body,
      );
  EmailData copyWithCompanion(i1.EmailCompanion data) {
    return EmailData(
      sender: data.sender.present ? data.sender.value : this.sender,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmailData(')
          ..write('sender: $sender, ')
          ..write('title: $title, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sender, title, body);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.EmailData &&
          other.sender == this.sender &&
          other.title == this.title &&
          other.body == this.body);
}

class EmailCompanion extends i0.UpdateCompanion<i1.EmailData> {
  final i0.Value<String> sender;
  final i0.Value<String> title;
  final i0.Value<String> body;
  final i0.Value<int> rowid;
  const EmailCompanion({
    this.sender = const i0.Value.absent(),
    this.title = const i0.Value.absent(),
    this.body = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  EmailCompanion.insert({
    required String sender,
    required String title,
    required String body,
    this.rowid = const i0.Value.absent(),
  }) : sender = i0.Value(sender),
       title = i0.Value(title),
       body = i0.Value(body);
  static i0.Insertable<i1.EmailData> custom({
    i0.Expression<String>? sender,
    i0.Expression<String>? title,
    i0.Expression<String>? body,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (sender != null) 'sender': sender,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.EmailCompanion copyWith({
    i0.Value<String>? sender,
    i0.Value<String>? title,
    i0.Value<String>? body,
    i0.Value<int>? rowid,
  }) {
    return i1.EmailCompanion(
      sender: sender ?? this.sender,
      title: title ?? this.title,
      body: body ?? this.body,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (sender.present) {
      map['sender'] = i0.Variable<String>(sender.value);
    }
    if (title.present) {
      map['title'] = i0.Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = i0.Variable<String>(body.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmailCompanion(')
          ..write('sender: $sender, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Fts5Drift extends i2.ModularAccessor {
  Fts5Drift(i0.GeneratedDatabase db) : super(db);
  i0.Selectable<i1.EmailData> emailsWithFts5() {
    return customSelect(
      'SELECT * FROM email WHERE email MATCH \'fts5\' ORDER BY rank',
      variables: [],
      readsFrom: {this.email},
    ).asyncMap(this.email.mapFromRow);
  }

  i1.Email get email =>
      i2.ReadDatabaseContainer(attachedDatabase).resultSet<i1.Email>('email');
}
