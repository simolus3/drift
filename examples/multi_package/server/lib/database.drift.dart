// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:shared/src/users.drift.dart' as i1;
import 'package:shared/src/posts.drift.dart' as i2;
import 'package:server/database.drift.dart' as i3;
import 'package:shared/shared.drift.dart' as i4;
import 'package:drift/internal/modular.dart' as i5;
import 'package:server/database.dart' as i6;

abstract class $ServerDatabase extends i0.GeneratedDatabase {
  $ServerDatabase(i0.QueryExecutor e) : super(e);
  $ServerDatabaseManager get managers => $ServerDatabaseManager(this);
  late final i1.$UsersTable users = i1.$UsersTable(this);
  late final i2.Posts posts = i2.Posts(this);
  late final i3.$ActiveSessionsTable activeSessions =
      i3.$ActiveSessionsTable(this);
  i4.SharedDrift get sharedDrift => i5.ReadDatabaseContainer(this)
      .accessor<i4.SharedDrift>(i4.SharedDrift.new);
  @override
  Iterable<i0.TableInfo<i0.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<i0.TableInfo<i0.Table, Object?>>();
  @override
  List<i0.DatabaseSchemaEntity> get allSchemaEntities =>
      [users, posts, activeSessions];
  @override
  i0.DriftDatabaseOptions get options =>
      const i0.DriftDatabaseOptions(storeDateTimeAsText: true);
}

class $ServerDatabaseManager {
  final $ServerDatabase _db;
  $ServerDatabaseManager(this._db);
  i1.$$UsersTableTableManager get users =>
      i1.$$UsersTableTableManager(_db, _db.users);
  i2.$PostsTableManager get posts => i2.$PostsTableManager(_db, _db.posts);
  i3.$$ActiveSessionsTableTableManager get activeSessions =>
      i3.$$ActiveSessionsTableTableManager(_db, _db.activeSessions);
}

class $ActiveSessionsTable extends i6.ActiveSessions
    with i0.TableInfo<$ActiveSessionsTable, i3.ActiveSession> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActiveSessionsTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _userMeta =
      const i0.VerificationMeta('user');
  @override
  late final i0.GeneratedColumn<int> user = i0.GeneratedColumn<int>(
      'user', aliasedName, false,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          i0.GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const i0.VerificationMeta _bearerTokenMeta =
      const i0.VerificationMeta('bearerToken');
  @override
  late final i0.GeneratedColumn<String> bearerToken =
      i0.GeneratedColumn<String>('bearer_token', aliasedName, false,
          type: i0.DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<i0.GeneratedColumn> get $columns => [user, bearerToken];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'active_sessions';
  @override
  i0.VerificationContext validateIntegrity(
      i0.Insertable<i3.ActiveSession> instance,
      {bool isInserting = false}) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user')) {
      context.handle(
          _userMeta, user.isAcceptableOrUnknown(data['user']!, _userMeta));
    } else if (isInserting) {
      context.missing(_userMeta);
    }
    if (data.containsKey('bearer_token')) {
      context.handle(
          _bearerTokenMeta,
          bearerToken.isAcceptableOrUnknown(
              data['bearer_token']!, _bearerTokenMeta));
    } else if (isInserting) {
      context.missing(_bearerTokenMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => const {};
  @override
  i3.ActiveSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i3.ActiveSession(
      user: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}user'])!,
      bearerToken: attachedDatabase.typeMapping.read(
          i0.DriftSqlType.string, data['${effectivePrefix}bearer_token'])!,
    );
  }

  @override
  $ActiveSessionsTable createAlias(String alias) {
    return $ActiveSessionsTable(attachedDatabase, alias);
  }
}

class ActiveSession extends i0.DataClass
    implements i0.Insertable<i3.ActiveSession> {
  final int user;
  final String bearerToken;
  const ActiveSession({required this.user, required this.bearerToken});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['user'] = i0.Variable<int>(user);
    map['bearer_token'] = i0.Variable<String>(bearerToken);
    return map;
  }

  i3.ActiveSessionsCompanion toCompanion(bool nullToAbsent) {
    return i3.ActiveSessionsCompanion(
      user: i0.Value(user),
      bearerToken: i0.Value(bearerToken),
    );
  }

  factory ActiveSession.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return ActiveSession(
      user: serializer.fromJson<int>(json['user']),
      bearerToken: serializer.fromJson<String>(json['bearerToken']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'user': serializer.toJson<int>(user),
      'bearerToken': serializer.toJson<String>(bearerToken),
    };
  }

  i3.ActiveSession copyWith({int? user, String? bearerToken}) =>
      i3.ActiveSession(
        user: user ?? this.user,
        bearerToken: bearerToken ?? this.bearerToken,
      );
  ActiveSession copyWithCompanion(i3.ActiveSessionsCompanion data) {
    return ActiveSession(
      user: data.user.present ? data.user.value : this.user,
      bearerToken:
          data.bearerToken.present ? data.bearerToken.value : this.bearerToken,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActiveSession(')
          ..write('user: $user, ')
          ..write('bearerToken: $bearerToken')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(user, bearerToken);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i3.ActiveSession &&
          other.user == this.user &&
          other.bearerToken == this.bearerToken);
}

class ActiveSessionsCompanion extends i0.UpdateCompanion<i3.ActiveSession> {
  final i0.Value<int> user;
  final i0.Value<String> bearerToken;
  final i0.Value<int> rowid;
  const ActiveSessionsCompanion({
    this.user = const i0.Value.absent(),
    this.bearerToken = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  ActiveSessionsCompanion.insert({
    required int user,
    required String bearerToken,
    this.rowid = const i0.Value.absent(),
  })  : user = i0.Value(user),
        bearerToken = i0.Value(bearerToken);
  static i0.Insertable<i3.ActiveSession> custom({
    i0.Expression<int>? user,
    i0.Expression<String>? bearerToken,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (user != null) 'user': user,
      if (bearerToken != null) 'bearer_token': bearerToken,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i3.ActiveSessionsCompanion copyWith(
      {i0.Value<int>? user,
      i0.Value<String>? bearerToken,
      i0.Value<int>? rowid}) {
    return i3.ActiveSessionsCompanion(
      user: user ?? this.user,
      bearerToken: bearerToken ?? this.bearerToken,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (user.present) {
      map['user'] = i0.Variable<int>(user.value);
    }
    if (bearerToken.present) {
      map['bearer_token'] = i0.Variable<String>(bearerToken.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActiveSessionsCompanion(')
          ..write('user: $user, ')
          ..write('bearerToken: $bearerToken, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

typedef $$ActiveSessionsTableCreateCompanionBuilder = i3.ActiveSessionsCompanion
    Function({
  required int user,
  required String bearerToken,
  i0.Value<int> rowid,
});
typedef $$ActiveSessionsTableUpdateCompanionBuilder = i3.ActiveSessionsCompanion
    Function({
  i0.Value<int> user,
  i0.Value<String> bearerToken,
  i0.Value<int> rowid,
});

class $$ActiveSessionsTableTableManager extends i0.RootTableManager<
    i0.GeneratedDatabase,
    i3.$ActiveSessionsTable,
    i3.ActiveSession,
    i3.$$ActiveSessionsTableFilterComposer,
    i3.$$ActiveSessionsTableOrderingComposer,
    $$ActiveSessionsTableCreateCompanionBuilder,
    $$ActiveSessionsTableUpdateCompanionBuilder,
    $$ActiveSessionsTableWithReferences,
    i3.ActiveSession> {
  $$ActiveSessionsTableTableManager(
      i0.GeneratedDatabase db, i3.$ActiveSessionsTable table)
      : super(i0.TableManagerState(
          db: db,
          table: table,
          filteringComposer: i3
              .$$ActiveSessionsTableFilterComposer(i0.ComposerState(db, table)),
          orderingComposer: i3.$$ActiveSessionsTableOrderingComposer(
              i0.ComposerState(db, table)),
          withReferenceMapper: (p0) => p0
              .map((e) => $$ActiveSessionsTableWithReferences(db, e))
              .toList(),
          updateCompanionCallback: ({
            i0.Value<int> user = const i0.Value.absent(),
            i0.Value<String> bearerToken = const i0.Value.absent(),
            i0.Value<int> rowid = const i0.Value.absent(),
          }) =>
              i3.ActiveSessionsCompanion(
            user: user,
            bearerToken: bearerToken,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int user,
            required String bearerToken,
            i0.Value<int> rowid = const i0.Value.absent(),
          }) =>
              i3.ActiveSessionsCompanion.insert(
            user: user,
            bearerToken: bearerToken,
            rowid: rowid,
          ),
        ));
}

typedef $$ActiveSessionsTableProcessedTableManager = i0.ProcessedTableManager<
    i0.GeneratedDatabase,
    i3.$ActiveSessionsTable,
    i3.ActiveSession,
    i3.$$ActiveSessionsTableFilterComposer,
    i3.$$ActiveSessionsTableOrderingComposer,
    $$ActiveSessionsTableCreateCompanionBuilder,
    $$ActiveSessionsTableUpdateCompanionBuilder,
    $$ActiveSessionsTableWithReferences,
    i3.ActiveSession>;

class $$ActiveSessionsTableFilterComposer
    extends i0.FilterComposer<i0.GeneratedDatabase, i3.$ActiveSessionsTable> {
  $$ActiveSessionsTableFilterComposer(super.$state);
  i0.ColumnFilters<String> get bearerToken => $state.composableBuilder(
      column: $state.table.bearerToken,
      builder: (column, joinBuilders) =>
          i0.ColumnFilters(column, joinBuilders: joinBuilders));

  i1.$$UsersTableFilterComposer get user {
    final i1.$$UsersTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.user,
        referencedTable: i5.ReadDatabaseContainer($state.db)
            .resultSet<i1.$UsersTable>('users'),
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            i1.$$UsersTableFilterComposer(i0.ComposerState(
                $state.db,
                i5.ReadDatabaseContainer($state.db)
                    .resultSet<i1.$UsersTable>('users'),
                joinBuilder,
                parentComposers)));
    return composer;
  }
}

class $$ActiveSessionsTableOrderingComposer
    extends i0.OrderingComposer<i0.GeneratedDatabase, i3.$ActiveSessionsTable> {
  $$ActiveSessionsTableOrderingComposer(super.$state);
  i0.ColumnOrderings<String> get bearerToken => $state.composableBuilder(
      column: $state.table.bearerToken,
      builder: (column, joinBuilders) =>
          i0.ColumnOrderings(column, joinBuilders: joinBuilders));

  i1.$$UsersTableOrderingComposer get user {
    final i1.$$UsersTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.user,
        referencedTable: i5.ReadDatabaseContainer($state.db)
            .resultSet<i1.$UsersTable>('users'),
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            i1.$$UsersTableOrderingComposer(i0.ComposerState(
                $state.db,
                i5.ReadDatabaseContainer($state.db)
                    .resultSet<i1.$UsersTable>('users'),
                joinBuilder,
                parentComposers)));
    return composer;
  }
}

class $$ActiveSessionsTableWithReferences {
  // ignore: unused_field
  final i0.GeneratedDatabase _db;
  final i3.ActiveSession i3ActiveSession;
  $$ActiveSessionsTableWithReferences(this._db, this.i3ActiveSession);
}
