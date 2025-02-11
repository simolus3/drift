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
      expect(resolved.buildSql(), 'SELECT COUNT(*) FROM users;');
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
        'a|lib/a.g.dart': decodedMatches(contains('extension on Database {')),
      }, outputs.dartOutputs, outputs);
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
