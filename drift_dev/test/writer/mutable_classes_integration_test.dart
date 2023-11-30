import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('generates mutable classes if needed', () async {
    const options = BuilderOptions({'mutable_classes': true});

    final writer = await emulateDriftBuild(inputs: {
      'a|lib/main.dart': r'''
import 'package:drift/drift.dart';

part 'main.drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

@DriftDatabase(
  tables: [Users],
  queries: {
    'someQuery': 'SELECT 1 AS foo, 2 AS bar;',
  },
)
class Database extends _$Database {}
''',
    }, options: options);

    checkOutputs(
      {
        'a|lib/main.drift.dart': IsValidDartFile(_WithoutFinalFields(
          {'User', 'UsersCompanion', 'SomeQueryResult'},
        )),
      },
      writer.dartOutputs,
      writer.writer,
    );
  }, tags: 'analyzer');
}

class _WithoutFinalFields extends Matcher {
  final Set<String> expectedWithoutFinals;

  const _WithoutFinalFields(this.expectedWithoutFinals);

  @override
  Description describe(Description description) {
    return description.add('generates classes $expectedWithoutFinals without '
        'final fields.');
  }

  @override
  bool matches(Object? desc, Map matchState) {
    // Parse the file, assure we don't have final fields in data classes.
    final parsed = desc;

    if (parsed is! CompilationUnit) {
      matchState['desc'] = 'Could not be parsed';
      return false;
    }

    final remaining = expectedWithoutFinals.toSet();

    final definedClasses = parsed.declarations.whereType<ClassDeclaration>();
    for (final definedClass in definedClasses) {
      final definedClassName = definedClass.name.lexeme;
      if (expectedWithoutFinals.contains(definedClassName)) {
        for (final member in definedClass.members) {
          if (member is FieldDeclaration) {
            if (member.fields.isFinal) {
              matchState['desc'] =
                  'Field ${member.fields.variables.first.name.lexeme} in '
                  '$definedClassName is final.';
              return false;
            }
          } else if (member is ConstructorDeclaration) {
            if (member.constKeyword != null) {
              matchState['desc'] = 'Constructor ${member.name?.lexeme ?? ''} '
                  'in $definedClassName is constant.';
              return false;
            }
          }
        }

        remaining.remove(definedClassName);
      }
    }

    // Also ensure that all expected classes were generated.
    if (remaining.isNotEmpty) {
      matchState['desc'] = 'Did not generate $remaining classes';
      return false;
    }

    return true;
  }

  @override
  Description describeMismatch(dynamic item, Description mismatchDescription,
      Map matchState, bool verbose) {
    return mismatchDescription
        .add((matchState['desc'] as String?) ?? 'Had syntax errors');
  }
}
