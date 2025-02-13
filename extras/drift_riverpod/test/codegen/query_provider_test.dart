import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:drift_dev/src/analysis/driver/error.dart';
import 'package:drift_riverpod/drift_riverpod.dart';
import 'package:drift_riverpod/src/codegen/query_provider.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('parse', () {
    test('definition without parameters', () async {
      final resolved = await _resolveExpectNoErrors('''
$commonDeclaration
@queryProvider
final users = database.magicQuery('SELECT COUNT(*) FROM users;');
''');

      expect(resolved.methodName, 'magicQuery');
      expect(resolved.parameterDeclarations, isNull);
      expect(resolved.buildSql(), 'SELECT COUNT(*) FROM users;');
    });

    test('definition with parameters', () async {
      final resolved = await _resolveExpectNoErrors('''
$commonDeclaration
@queryProvider
final users = database.magicQuery((id, suffix) => 'SELECT name || \$suffix FROM users WHERE id = \$id;');
''');

      expect(resolved.methodName, 'magicQuery');
      expect(resolved.parameterDeclarations, isNotNull);
      expect(
          resolved.buildSql(), 'SELECT name || ?1 FROM users WHERE id = ?2;');
      expect(resolved.parameters[0].name, 'id');
      expect(resolved.parameters[0].sqlIndex, 2);
      expect(resolved.parameters[0].dartIndex, 0);
      expect(resolved.parameters[1].name, 'suffix');
      expect(resolved.parameters[1].sqlIndex, 1);
      expect(resolved.parameters[1].dartIndex, 1);
    });
  });

  group('generate', () {
    test('definition without parameters', () async {
      final outputs = await emulateDriftBuild(
        inputs: {
          'a|lib/a.dart': '''
$commonDeclaration
@queryProvider
final users = database.magicQuery('SELECT COUNT(*) FROM users;');
''',
        },
        logger: loggerThat(neverEmits(anything)),
      );

      checkOutputs({
        'a|lib/a.drift_riverpod.g.part': decodedMatches(contains('''
extension on DatabaseProvider<Database> {
  SelectableProvider<List<int>> magicQuery(String _) {
    return queryProviderImpl((ref) => ref.watch(database).users());
  }
}''')),
      }, outputs.driftRiverpodOutputs, outputs);
    });

    test('with parameters', () async {
      final outputs = await emulateDriftBuild(
        inputs: {
          'a|lib/a.dart': '''
$commonDeclaration
@queryProvider
final users = database.magicQuery((id, suffix) => 'SELECT name || \$suffix FROM users WHERE id = \$id;');
''',
        },
        logger: loggerThat(neverEmits(anything)),
      );

      checkOutputs({
        'a|lib/a.drift_riverpod.g.part': decodedMatches(allOf(
          contains(r'''
extension on Database {
  Selectable<String> users(String var1, int var2) {
    return customSelect(
      'SELECT name || ?1 AS _c0 FROM users WHERE id = ?2',
      variables: [Variable<String>(var1), Variable<int>(var2)],
      readsFrom: {users},
    ).map((QueryRow row) => row.read<String>('_c0'));
  }
}'''),
          contains(r'''
extension on DatabaseProvider<Database> {
  SelectableProviderFamily<List<String>, (int id, String suffix)> magicQuery(
    Object _,
  ) {
    return queryProviderFamilyImpl(
      (ref, args) => ref.watch(database).users(args.$2, args.$1),
    );
  }
}
'''),
        )),
      }, outputs.driftRiverpodOutputs, outputs);
    });

    test('referencing other providers', () async {
      final outputs = await emulateDriftBuild(
        inputs: {
          'a|lib/a.dart': '''
$commonDeclaration

final Provider<int> currentId = Provider((ref) => 1);

@queryProvider
final users = database.magicQuery((ref) => 'SELECT * FROM users WHERE id = \${ref.watch(currentId)};');
''',
        },
        logger: loggerThat(neverEmits(anything)),
      );

      checkOutputs({
        'a|lib/a.drift_riverpod.g.part': decodedMatches(contains(r'''
    return queryProviderImpl(
      (ref) => ref.watch(database).users(ref.watch(currentId)),
    );
''')),
      }, outputs.driftRiverpodOutputs, outputs);
    });
  });
}

const commonDeclaration = r'''
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:riverpod/riverpod.dart';
import 'package:drift_riverpod/drift_riverpod.dart';

part 'a.g.dart';

class Users extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
}

@DriftDatabase(tables: [Users])
class Database extends GeneratedDatabase {
  Database(super.e);

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];
}

final database = StateProvider((ref) {
  return Database(NativeDatabase.memory());
});
''';

Future<QueryProviderDefinition> _resolveExpectNoErrors(String source) async {
  final (definition, errors) = await _resolveSingle(source);

  expect(errors, isEmpty);
  return definition!;
}

Future<(QueryProviderDefinition?, List<DriftAnalysisError>)> _resolveSingle(
    String source) async {
  final id = AssetId('a', 'lib/a.dart');
  final checker = TypeChecker.fromRuntime(QueryProvider);

  return await resolveSource(source, (resolver) async {
    final library = await resolver.libraryFor(id);
    final reader = LibraryReader(library);
    final target = reader.annotatedWith(checker).single;
    final declaration =
        await resolver.astNodeFor(target.element, resolve: true);

    return QueryProviderDefinition.parse(target.element, declaration!);
  }, inputId: id);
}
