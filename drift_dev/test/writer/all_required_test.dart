import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('generates classes with required parameters', () async {
    const options =
        BuilderOptions({'row_class_constructor_all_required': true});

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
        'a|lib/main.drift.dart':
            IsValidDartFile(const _DefaultConstructorAllRequired(
          {'User', 'UsersCompanion', 'SomeQueryResult'},
        )),
      },
      writer.dartOutputs,
      writer.writer,
    );
  }, tags: 'analyzer');
}

class _DefaultConstructorAllRequired extends Matcher {
  final Set<String> classesToCheck;

  const _DefaultConstructorAllRequired(this.classesToCheck);

  @override
  Description describe(Description description) {
    return description.add('generates classes $classesToCheck without '
        'non-required parameters in default constructor.');
  }

  @override
  bool matches(Object? desc, Map matchState) {
    // Parse the file, assure we don't have final fields in data classes.
    final parsed = desc;

    if (parsed is! CompilationUnit) {
      matchState['desc'] = 'Could not be parsed';
      return false;
    }

    final remaining = classesToCheck.toSet();

    final definedClasses = parsed.declarations.whereType<ClassDeclaration>();
    for (final definedClass in definedClasses) {
      final definedClassName = definedClass.name.lexeme;
      if (classesToCheck.contains(definedClassName)) {
        for (final member in definedClass.members) {
          if (member is ConstructorDeclaration && member.name == null) {
            for (final parameter in member.parameters.parameters) {
              if (!parameter.isRequired) {
                matchState['desc'] = 'Parameter ${parameter.name?.lexeme} in '
                    '$definedClassName() is not required.';
              }
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
