import 'package:drift/drift.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../generated/converter.dart';
import '../generated/custom_tables.dart';
import '../test_utils/test_utils.dart';

const _createNoIds =
    'CREATE TABLE IF NOT EXISTS no_ids (payload BLOB NOT NULL PRIMARY KEY) '
    'WITHOUT ROWID;';

const _createWithDefaults = 'CREATE TABLE IF NOT EXISTS with_defaults ('
    "a TEXT DEFAULT 'something', b INTEGER UNIQUE);";

const _createWithConstraints = 'CREATE TABLE IF NOT EXISTS with_constraints ('
    'a TEXT, b INTEGER NOT NULL, c REAL, '
    'FOREIGN KEY (a, b) REFERENCES with_defaults (a, b)'
    ');';

const _createConfig = 'CREATE TABLE IF NOT EXISTS config ('
    'config_key TEXT not null primary key, '
    'config_value TEXT, '
    'sync_state INTEGER, '
    'sync_state_implicit INTEGER) STRICT;';

const _createMyTable = 'CREATE TABLE IF NOT EXISTS mytable ('
    'someid INTEGER NOT NULL, '
    'sometext TEXT, '
    'is_inserting INTEGER, '
    'somedate TEXT, '
    'PRIMARY KEY (someid DESC)'
    ');';

const _createEmail = 'CREATE VIRTUAL TABLE IF NOT EXISTS email USING '
    'fts5(sender, title, body);';

const _createMyTrigger =
    'CREATE TRIGGER my_trigger AFTER INSERT ON config BEGIN '
    'INSERT INTO with_defaults '
    'VALUES (new.config_key, LENGTH(new.config_value));'
    'END';

const _createValueIndex =
    'CREATE INDEX IF NOT EXISTS value_idx ON config (config_value)';

const _createMyView =
    'CREATE VIEW my_view AS SELECT * FROM config WHERE sync_state = 2';

const _defaultInsert = 'INSERT INTO config (config_key, config_value) '
    "VALUES ('key', 'values')";

void main() {
  // see ../data/tables/tables.drift
  late MockExecutor mock;
  late CustomTablesDb db;

  setUp(() {
    mock = MockExecutor();
    db = CustomTablesDb(mock);
  });

  tearDown(() => db.close());

  test('creates everything as specified in .drift files', () async {
    await db.createMigrator().createAll();

    verify(mock.runCustom(_createNoIds, []));
    verify(mock.runCustom(_createWithDefaults, []));
    verify(mock.runCustom(_createWithConstraints, []));
    verify(mock.runCustom(_createConfig, []));
    verify(mock.runCustom(_createMyTable, []));
    verify(mock.runCustom(_createEmail, []));
    verify(mock.runCustom(_createMyTrigger, []));
    verify(mock.runCustom(_createMyView, []));
    verify(mock.runCustom(_createValueIndex, []));
    verify(mock.runCustom(_defaultInsert, []));
  });

  test('can create trigger manually', () async {
    await db.createMigrator().createTrigger(db.myTrigger);
    verify(mock.runCustom(_createMyTrigger, []));
  });

  test('can create index manually', () async {
    await db.createMigrator().createIndex(db.valueIdx);
    verify(mock.runCustom(_createValueIndex, []));
  });

  test('infers primary keys correctly', () async {
    expect(db.noIds.primaryKey, [db.noIds.payload]);
    expect(db.withDefaults.primaryKey, isEmpty);
    expect(db.config.primaryKey, [db.config.configKey]);
    expect(db.mytable.primaryKey, [db.mytable.someid]);
  });

  test('supports absent values for primary key integers', () async {
    // regression test for #112: https://github.com/simolus3/drift/issues/112

    await db.into(db.mytable).insert(const MytableCompanion());
    verify(mock.runInsert('INSERT INTO mytable DEFAULT VALUES', []));
  });

  test('runs queries with arrays and Dart templates', () async {
    await db.readMultiple(['a', 'b'],
        clause: (config) =>
            OrderBy([OrderingTerm(expression: config.configKey)])).get();

    verify(mock.runSelect(
      'SELECT * FROM config WHERE config_key IN (?1, ?2) '
      'ORDER BY config_key ASC',
      ['a', 'b'],
    ));
  });

  test('runs query with variables from template', () async {
    final mockResponse = {'config_key': 'key', 'config_value': 'value'};
    when(mock.runSelect(any, any))
        .thenAnswer((_) => Future.value([mockResponse]));

    final parsed = await db
        .readDynamic(predicate: (config) => config.configKey.equals('key'))
        .getSingle();

    verify(
        mock.runSelect('SELECT * FROM config WHERE config_key = ?1', ['key']));
    expect(parsed, const Config(configKey: 'key', configValue: 'value'));
  });

  test('applies default parameter expressions when not set', () async {
    await db.readDynamic().getSingleOrNull();

    verify(mock.runSelect('SELECT * FROM config WHERE (TRUE)', []));
  });

  test('columns use table names in queries with multiple tables', () async {
    await db.multiple(predicate: (d, c) => d.a.equals('foo')).get();

    verify(mock.runSelect(argThat(contains('d.a = ?1')), any));
  });

  test('order by-params are ignored by default', () async {
    await db.readMultiple(['foo']).get();
    verify(mock.runSelect(argThat(isNot(contains('with_defaults.a'))), any));
  });

  test('runs queries with nested results', () async {
    const row = {
      'a': 'text for a',
      'b': 42,
      'nested_0.a': 'text',
      'nested_0.b': 1337,
      'nested_0.c': 18.7,
    };

    when(mock.runSelect(any, any)).thenAnswer((_) {
      return Future.value([row]);
    });

    final result = await db
        .multiple(predicate: (_, __) => const Constant(true))
        .getSingle();

    expect(
      result,
      MultipleResult(
        row: QueryRow(row, db),
        a: 'text for a',
        b: 42,
        c: const WithConstraint(a: 'text', b: 1337, c: 18.7),
      ),
    );
  });

  test('runs queries with nested results that are null', () async {
    const row = {
      'a': 'text for a',
      'b': 42,
      'nested_0.a': 'text',
      'nested_0.b': null, // note: with_constraints.b is NOT NULL in the db
      'nested_0.c': 18.7,
    };

    when(mock.runSelect(any, any)).thenAnswer((_) {
      return Future.value([row]);
    });

    final result = await db
        .multiple(predicate: (_, __) => const Constant(true))
        .getSingle();

    expect(
      result,
      MultipleResult(
        row: QueryRow(row, db),
        a: 'text for a',
        b: 42,
        // Since a non-nullable column in c was null, table should be null
        c: null,
      ),
    );
  });

  test('applies column name mapping when needed', () async {
    when(mock.runSelect(any, any)).thenAnswer((_) async {
      return [
        {
          'ck': 'key',
          'cf': 'value',
          'cs1': 1,
          'cs2': 1,
        }
      ];
    });

    final entry = await db.readConfig('key').getSingle();
    expect(
      entry,
      const Config(
        configKey: 'key',
        configValue: 'value',
        syncState: SyncType.locallyUpdated,
        syncStateImplicit: SyncType.locallyUpdated,
      ),
    );
  });

  test('applies type converters to variables', () async {
    when(mock.runSelect(any, any)).thenAnswer((_) => Future.value([]));
    await db.typeConverterVar(SyncType.locallyCreated,
        [SyncType.locallyUpdated, SyncType.synchronized]).get();

    verify(mock.runSelect(
        'SELECT config_key FROM config WHERE (TRUE) AND(sync_state = ?1 '
        'OR sync_state_implicit IN (?2, ?3))',
        [0, 1, 2]));
  });

  test('can pass unconverted type to generated columns', () async {
    await (db.select(db.config)
          ..where((tbl) => tbl.syncState.equalsValue(SyncType.synchronized)))
        .getSingleOrNull();

    verify(mock.runSelect('SELECT * FROM config WHERE sync_state = ?;',
        [ConfigTable.$converter0.toSql(SyncType.synchronized)]));
  });
}
