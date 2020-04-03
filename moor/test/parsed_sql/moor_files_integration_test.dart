import 'package:moor/moor.dart';
import 'package:test/test.dart';

import '../data/tables/custom_tables.dart';
import '../data/utils/mocks.dart';

const _createNoIds =
    'CREATE TABLE IF NOT EXISTS no_ids (payload BLOB NOT NULL PRIMARY KEY) '
    'WITHOUT ROWID;';

const _createWithDefaults = 'CREATE TABLE IF NOT EXISTS with_defaults ('
    "a VARCHAR DEFAULT 'something', b INTEGER UNIQUE);";

const _createWithConstraints = 'CREATE TABLE IF NOT EXISTS with_constraints ('
    'a VARCHAR, b INTEGER NOT NULL, c REAL, '
    'FOREIGN KEY (a, b) REFERENCES with_defaults (a, b)'
    ');';

const _createConfig = 'CREATE TABLE IF NOT EXISTS config ('
    'config_key VARCHAR not null primary key, '
    'config_value VARCHAR, '
    'sync_state INTEGER);';

const _createMyTable = 'CREATE TABLE IF NOT EXISTS mytable ('
    'someid INTEGER NOT NULL PRIMARY KEY, '
    'sometext VARCHAR, '
    'somebool INTEGER, '
    'somedate INTEGER);';

const _createEmail = 'CREATE VIRTUAL TABLE IF NOT EXISTS email USING '
    'fts5(sender, title, body);';

const _createMyTrigger =
    '''CREATE TRIGGER my_trigger AFTER INSERT ON config BEGIN
  INSERT INTO with_defaults VALUES (new.config_key, LENGTH(new.config_value));
END;''';

const _createValueIndex =
    'CREATE INDEX IF NOT EXISTS value_idx ON config (config_value);';

const _defaultInsert = 'INSERT INTO config (config_key, config_value) '
    "VALUES ('key', 'values')";

void main() {
  // see ../data/tables/tables.moor
  test('creates everything as specified in .moor files', () async {
    final mockExecutor = MockExecutor();
    final db = CustomTablesDb(mockExecutor);
    await db.createMigrator().createAll();

    verify(mockExecutor.runCustom(_createNoIds, []));
    verify(mockExecutor.runCustom(_createWithDefaults, []));
    verify(mockExecutor.runCustom(_createWithConstraints, []));
    verify(mockExecutor.runCustom(_createConfig, []));
    verify(mockExecutor.runCustom(_createMyTable, []));
    verify(mockExecutor.runCustom(_createEmail, []));
    verify(mockExecutor.runCustom(_createMyTrigger, []));
    verify(mockExecutor.runCustom(_createValueIndex, []));
    verify(mockExecutor.runCustom(_defaultInsert, []));
  });

  test('can create trigger manually', () async {
    final mockExecutor = MockExecutor();
    final db = CustomTablesDb(mockExecutor);

    await db.createMigrator().createTrigger(db.myTrigger);
    verify(mockExecutor.runCustom(_createMyTrigger, []));
  });

  test('can create index manually', () async {
    final mockExecutor = MockExecutor();
    final db = CustomTablesDb(mockExecutor);

    await db.createMigrator().createIndex(db.valueIdx);
    verify(mockExecutor.runCustom(_createValueIndex, []));
  });

  test('infers primary keys correctly', () async {
    final db = CustomTablesDb(null);

    expect(db.noIds.primaryKey, [db.noIds.payload]);
    expect(db.withDefaults.primaryKey, isEmpty);
    expect(db.config.primaryKey, [db.config.configKey]);
  });

  test('supports absent values for primary key integers', () async {
    // regression test for #112: https://github.com/simolus3/moor/issues/112
    final mock = MockExecutor();
    final db = CustomTablesDb(mock);

    await db.into(db.mytable).insert(const MytableCompanion());
    verify(mock.runInsert('INSERT INTO mytable DEFAULT VALUES', []));
  });

  test('runs queries with arrays and Dart templates', () async {
    final mock = MockExecutor();
    final db = CustomTablesDb(mock);

    await db.readMultiple(['a', 'b'],
        OrderBy([OrderingTerm(expression: db.config.configKey)])).get();

    verify(mock.runSelect(
      'SELECT * FROM config WHERE config_key IN (?1, ?2) '
      'ORDER BY config_key ASC',
      ['a', 'b'],
    ));
  });

  test('runs query with variables from template', () async {
    final mock = MockExecutor();
    final db = CustomTablesDb(mock);

    final mockResponse = {'config_key': 'key', 'config_value': 'value'};
    when(mock.runSelect(any, any))
        .thenAnswer((_) => Future.value([mockResponse]));

    final parsed =
        await db.readDynamic(db.config.configKey.equals('key')).getSingle();

    verify(
        mock.runSelect('SELECT * FROM config WHERE config_key = ?', ['key']));
    expect(parsed, Config(configKey: 'key', configValue: 'value'));
  });

  test('columns use table names in queries with multiple tables', () async {
    final mock = MockExecutor();
    final db = CustomTablesDb(mock);

    await db.multiple(db.withDefaults.a.equals('foo')).get();

    verify(mock.runSelect(argThat(contains('with_defaults.a')), any));
  });

  test('runs queries with nested results', () async {
    final mock = MockExecutor();
    final db = CustomTablesDb(mock);

    when(mock.runSelect(any, any)).thenAnswer((_) {
      final row = {
        'a': 'text for a',
        'b': 42,
        'nested_0.a': 'text',
        'nested_0.b': 1337,
        'nested_0.c': 18.7,
      };

      return Future.value([row]);
    });

    final result = await db.multiple(const Constant(true)).getSingle();

    expect(
      result,
      MultipleResult(
        a: 'text for a',
        b: 42,
        c: WithConstraint(a: 'text', b: 1337, c: 18.7),
      ),
    );
  });

  test('runs queries with nested results that are null', () async {
    final mock = MockExecutor();
    final db = CustomTablesDb(mock);

    when(mock.runSelect(any, any)).thenAnswer((_) {
      return Future.value([
        {
          'a': 'text for a',
          'b': 42,
          'nested_0.a': 'text',
          'nested_0.b': null, // note: with_constraints.b is NOT NULL in the db
          'nested_0.c': 18.7,
        }
      ]);
    });

    final result = await db.multiple(const Constant(true)).getSingle();

    expect(
      result,
      MultipleResult(
        a: 'text for a',
        b: 42,
        // Since a non-nullable column in c was null, table should be null
        c: null,
      ),
    );
  });
}
