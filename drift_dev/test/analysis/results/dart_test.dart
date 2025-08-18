import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/analysis/results/dart.dart';
import 'package:drift_dev/src/writer/import_manager.dart';
import 'package:drift_dev/src/writer/writer.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  late TestBackend tester;

  setUpAll(() async => tester = await TestBackend.init({
        'a|lib/definitions.dart': '''
extension MyStringUtils on String {
  String reverse() => throw 'todo';
}
''',
      }));
  tearDownAll(() => tester.dispose());

  group('from AST', () {
    int testCount = 0;

    Future<void> checkTransformation(String sourceExpression,
        String expectedResult, Map<String, String> expectedImports) async {
      final testUri = Uri.parse('package:a/test_${testCount++}.dart');
      final expression =
          await tester.resolveExpression(testUri, sourceExpression, const [
        'package:a/definitions.dart',
        'package:drift/drift.dart',
      ]);
      final annotated = AnnotatedDartCode.ast(expression);

      final imports = TestImportManager();
      final writer = Writer(
        const DriftOptions.defaults(),
        generationOptions: GenerationOptions(
          imports: imports,
        ),
      );

      final code = writer.dartCode(annotated);

      expect(code, expectedResult);
      expectedImports.forEach((alias, import) {
        expect(imports.importAliases[Uri.parse(import)], alias);
      });
    }

    test('constructor invocation', () async {
      await checkTransformation('const Duration(seconds: 12)',
          'const i0.Duration(seconds: 12)', {'i0': 'dart:core'});
    });

    test('static invocation', () async {
      await checkTransformation(
          'Uri.parse("")', 'i0.Uri.parse("")', {'i0': 'dart:core'});
    });

    test('explicit extension invocation', () async {
      await checkTransformation(
          'IterableExtensions<String>([]).firstOrNull',
          'i0.IterableExtensions<i1.String>([]).firstOrNull',
          {'i0': 'dart:collection', 'i1': 'dart:core'});
    });

    test('extension method invocations', () async {
      await checkTransformation(
        "'hello world'.reverse()",
        "i0.MyStringUtils('hello world').reverse()",
        {'i0': 'package:a/definitions.dart'},
      );

      await checkTransformation(
        "'hello world'?.reverse<void>(1, 2, 3)",
        "i0.MyStringUtils('hello world')?.reverse<void>(1,2,3)",
        {'i0': 'package:a/definitions.dart'},
      );
    });

    test('explicit type arguments on extension', () async {
      await checkTransformation(
        "CustomExpression<DateTime>('creation_time')",
        "i0.CustomExpression<i1.DateTime>('creation_time')",
        {
          'i0': 'package:drift/src/runtime/query_builder/query_builder.dart',
          'i1': 'dart:core',
        },
      );
    });

    test('includes commas for function definitions', () {
      // Regression test for https://github.com/simolus3/drift/issues/3608
      final file = parseString(content: '''
final x = (json) => (json! as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, v as List<int>),
          );
''');

      final variable =
          file.unit.childEntities.single as TopLevelVariableDeclaration;
      final initializer = variable.variables.variables.single.initializer!;
      final ast = AnnotatedDartCode.ast(initializer);

      final writer = Writer(
        const DriftOptions.defaults(),
        generationOptions: GenerationOptions(imports: NullImportManager()),
      );

      final code = writer.dartCode(ast);
      expect(code,
          '(json) => (json! as Map<String,dynamic>).map((k, v) => MapEntry(k,v as List<int>))');
    });
  });
}
