import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:drift_dev/src/backends/build/drift_builder.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

const _testInput = r'''
import 'package:drift/drift.dart';

part 'main.moor.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

@DriftDatabase(
  tables: [Users],
)
class Database extends _$Database {}
''';

void main() {
  test(
    'generates const constructor for data classes can companion classes',
    () async {
      await testBuilder(
        DriftPartBuilder(const BuilderOptions({})),
        const {'a|lib/main.dart': _testInput},
        reader: await PackageAssetReader.currentIsolate(),
        outputs: const {
          'a|lib/main.moor.dart': _GeneratesConstDataClasses(
            {'User', 'UsersCompanion'},
          ),
        },
      );
    },
    tags: 'analyzer',
  );
}

class _GeneratesConstDataClasses extends Matcher {
  final Set<String> expectedWithConstConstructor;

  const _GeneratesConstDataClasses(this.expectedWithConstConstructor);

  @override
  Description describe(Description description) {
    return description.add('generates classes $expectedWithConstConstructor '
        'const constructor.');
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
        sdkLanguageVersion: Version(2, 12, 0),
        flags: const [],
      ),
      resourceProvider: resourceProvider,
      throwIfDiagnostics: true,
    ).unit;

    final remaining = expectedWithConstConstructor.toSet();

    final definedClasses = parsed.declarations.whereType<ClassDeclaration>();
    for (final definedClass in definedClasses) {
      if (expectedWithConstConstructor.contains(definedClass.name.name)) {
        final constructor = definedClass.getConstructor(null);
        if (constructor?.constKeyword == null) {
          matchState['desc'] = 'Constructor ${definedClass.name.name} is not '
              'const.';
          return false;
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
    return mismatchDescription
        .add((matchState['desc'] as String?) ?? 'Had syntax errors');
  }
}
