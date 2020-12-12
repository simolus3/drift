import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:moor_generator/src/backends/build/moor_builder.dart';
import 'package:test/test.dart';
import 'package:pub_semver/pub_semver.dart';

const _testInput = r'''
import 'package:moor/moor.dart';

part 'main.moor.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

@UseMoor(
  tables: [Users],
  queries: {
    'someQuery': 'SELECT 1 AS foo, 2 AS bar;',
  },
)
class Database extends _$Database {}
''';

void main() {
  group('generates mutable classes if needed', () {
    Future<void> _testWith(bool nnbd) async {
      await testBuilder(
        MoorPartBuilder(const BuilderOptions({'mutable_classes': true})),
        {'a|lib/main.dart': nnbd ? _testInput : '//@dart=2.6\n$_testInput'},
        reader: await PackageAssetReader.currentIsolate(),
        outputs: {
          'a|lib/main.moor.dart': _GeneratesWithoutFinalFields(
            {'User', 'UsersCompanion', 'SomeQueryResult'},
            isNullSafe: nnbd,
          ),
        },
      );
    }

    test('null-safety', () => _testWith(true));
    test('legacy', () => _testWith(false));
  }, tags: 'analyzer');
}

class _GeneratesWithoutFinalFields extends Matcher {
  final Set<String> expectedWithoutFinals;
  final bool isNullSafe;

  const _GeneratesWithoutFinalFields(this.expectedWithoutFinals,
      {this.isNullSafe = false});

  @override
  Description describe(Description description) {
    return description.add('generates classes $expectedWithoutFinals without '
        'final fields.');
  }

  @override
  bool matches(dynamic desc, Map matchState) {
    // Parse the file, assure we don't have final fields in data classes.
    final resourceProvider = MemoryResourceProvider();
    if (desc is List<int>) {
      resourceProvider.newFileWithBytes('/foo.dart', desc);
    } else if (desc is String) {
      resourceProvider.newFile('/foo.dart', desc);
    } else {
      desc['desc'] = 'Neither a List<int> or String - cannot be parsed';
      return false;
    }

    final parsed = parseFile(
      path: '/foo.dart',
      featureSet: FeatureSet.fromEnableFlags2(
        sdkLanguageVersion: Version(2, isNullSafe ? 12 : 6, 0),
        flags: const [],
      ),
      resourceProvider: resourceProvider,
      throwIfDiagnostics: true,
    ).unit;

    final remaining = expectedWithoutFinals.toSet();

    final definedClasses = parsed.declarations.whereType<ClassDeclaration>();
    for (final definedClass in definedClasses) {
      if (expectedWithoutFinals.contains(definedClass.name.name)) {
        for (final member in definedClass.members) {
          if (member is FieldDeclaration) {
            if (member.fields.isFinal) {
              matchState['desc'] =
                  'Field ${member.fields.variables.first.name.name} in '
                  '${definedClass.name.name} is final.';
              return false;
            }
          } else if (member is ConstructorDeclaration) {
            if (member.constKeyword != null) {
              matchState['desc'] = 'Constructor ${member.name?.name ?? ''} in '
                  '${definedClass.name.name} is constant.';
              return false;
            }
          }
        }

        remaining.remove(definedClass.name.name);
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
    return mismatchDescription.add(matchState['desc'] as String);
  }
}
