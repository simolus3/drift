import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:collection/collection.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test(
    'generates const constructor for data classes can companion classes',
    () async {
      final writer = await emulateDriftBuild(
        inputs: const {
          'a|lib/main.dart': r'''
import 'package:drift/drift.dart';

part 'main.drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

@DriftDatabase(
  tables: [Users],
)
class Database extends _$Database {}
'''
        },
      );

      checkOutputs(const {
        'a|lib/main.drift.dart': _GeneratesConstDataClasses(
          {'User', 'UsersCompanion'},
        ),
      }, writer.dartOutputs, writer.writer);
    },
    tags: 'analyzer',
  );

  test(
    'generates async mapping code for existing row class with async factory',
    () async {
      final writer = await emulateDriftBuild(
        inputs: const {
          'a|lib/main.dart': r'''
import 'package:drift/drift.dart';

part 'main.drift.dart';

@UseRowClass(MyCustomClass, constructor: 'load')
class Tbl extends Table {
  TextColumn get foo => text()();
  IntColumn get bar => integer()();
}

class MyCustomClass {
  static Future<MyCustomClass> load(String foo, int bar) async {
    throw 'stub';
  }
}

@DriftDatabase(
  tables: [Tbl],
)
class Database extends _$Database {}
'''
        },
      );

      checkOutputs({
        'a|lib/main.drift.dart': decodedMatches(contains(r'''
  @override
  Future<MyCustomClass> map(Map<String, dynamic> data,
      {String? tablePrefix}) async {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return await MyCustomClass.load(
      attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}foo'])!,
      attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bar'])!,
    );
  }
''')),
      }, writer.dartOutputs, writer.writer);
    },
    tags: 'analyzer',
  );
  test(
    'It should generate a type converter using the EnumNameConverter when textEnum is used',
    () async {
      final writer = await emulateDriftBuild(
        inputs: const {
          'a|lib/main.dart': r'''
import 'package:drift/drift.dart';

part 'main.drift.dart';

enum Priority { low, medium, high }

class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get priority => textEnum<Priority>()();
}

@DriftDatabase(
  tables: [Todos],
)
class Database extends _$Database {}
'''
        },
      );

      checkOutputs({
        'a|lib/main.drift.dart': decodedMatches(contains(r'''
  static JsonTypeConverter2<Priority, String, String> $converterpriority =
      const EnumNameConverter<Priority>(Priority.values);''')),
      }, writer.dartOutputs, writer.writer);
    },
    tags: 'analyzer',
  );

  test('can write mixins providing toColumns method', () async {
    final writer = await emulateDriftBuild(
      inputs: {
        'a|lib/main.drift': '''
import 'row.dart';

CREATE TABLE users (
  id INTEGER NOT NULL PRIMARY KEY,
  name TEXT NOT NULL
);

CREATE TABLE posts (
  id INTEGER NOT NULL PRIMARY KEY,
  content TEXT NOT NULL
) WITH Post;
''',
        'a|lib/row.dart': '''
import 'main.drift.dart';

class Post with PostsToColumns {
  @override
  final int id;
  @override
  final String content;

  Post(this.id, this.content);
}
''',
      },
      logger: loggerThat(neverEmits(anything)),
      modularBuild: true,
      options: BuilderOptions({'write_to_columns_mixins': true}),
    );

    checkOutputs({
      'a|lib/main.drift.dart': decodedMatches(contains('''
mixin PostsToColumns implements i1.Insertable<i2.Post> {
  int get id;
  String get content;
  @override
  Map<String, i1.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i1.Expression>{};
    map['id'] = i1.Variable<int>(id);
    map['content'] = i1.Variable<String>(content);
    return map;
  }
}
''')),
    }, writer.dartOutputs, writer.writer);
  });

  test('generates correct fromJson for nullable converters', () async {
    // Regression test for https://github.com/simolus3/drift/issues/2281
    final result = await emulateDriftBuild(
      inputs: {
        'a|lib/a.dart': '''
import 'package:drift/drift.dart';

class MyModel {}

class MyConverter
    extends TypeConverter<MyModel?, String?>
    with JsonTypeConverter<MyModel?, String?> {
  const MyConverter();
}

class MyTable extends Table {
  TextColumn get invoiceContact => text()
      .map(const MyConverter()).nullable()();
}
''',
      },
      modularBuild: true,
    );

    checkOutputs({
      'a|lib/a.drift.dart': decodedMatches(contains(r'''
  factory MyTableData.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return MyTableData(
      invoiceContact: i1.$MyTableTable.$converterinvoiceContact
          .fromJson(serializer.fromJson<String?>(json['invoiceContact'])),
    );
  }''')),
    }, result.dartOutputs, result.writer);
  });

  test('generates correct companions for modular row classes', () async {
    final result = await emulateDriftBuild(
      inputs: {
        'a|lib/a.dart': '''
import 'package:drift/drift.dart';

@UseRowClass(Item, generateInsertable: true)
class ItemTable extends Table {
  IntColumn get id => integer().autoIncrement()();
}

class Item {
  final int id;
  Item(this.id);
}
''',
      },
      modularBuild: true,
    );

    checkOutputs(
      {
        'a|lib/a.drift.dart': decodedMatches(
          allOf(
            // The toString() definition for companions was broken and included
            // the import prefix of the companion.
            contains("StringBuffer('ItemTableCompanion(')"),

            // The extension should also reference the row class correctly
            contains(r'''
class _$ItemInsertable implements i0.Insertable<i1.Item> {
  i1.Item _object;
  _$ItemInsertable(this._object);
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    return i2.ItemTableCompanion(
      id: i0.Value(_object.id),
    ).toColumns(false);
  }
}

extension ItemToInsertable on i1.Item {
  _$ItemInsertable toInsertable() {
    return _$ItemInsertable(this);
  }
}
'''),
          ),
        ),
      },
      result.dartOutputs,
      result.writer,
    );
  });

  test(
    'It should use the provided names for the data classes and the companion class',
    () async {
      final writer = await emulateDriftBuild(
        inputs: const {
          'a|lib/main.dart': r'''
import 'package:drift/drift.dart';

part 'main.drift.dart';

@DataClassName('FirstDataClass', companion: 'FirstCompanionClass')
class FirstTable extends Table {
  TextColumn get foo => text()();
  IntColumn get bar => integer()();
}

@DataClassName.custom(name: 'SecondDataClass', companion: 'SecondCompanionClass')
class SecondTable extends Table {
  TextColumn get foo => text()();
  IntColumn get bar => integer()();
}

@DriftDatabase(
  tables: [FirstTable, SecondTable],
)
class Database extends _$Database {}
'''
        },
      );

      checkOutputs({
        'a|lib/main.drift.dart': decodedMatches(allOf([
          contains(
            'class FirstDataClass extends DataClass implements Insertable<FirstDataClass> {',
          ),
          contains(
            'class FirstTableCompanion extends UpdateCompanion<FirstDataClass> {',
          ),
          contains(
            'class SecondDataClass extends DataClass implements Insertable<SecondDataClass> {',
          ),
          contains(
            'class SecondTableCompanion extends UpdateCompanion<SecondDataClass> {',
          ),
        ])),
      }, writer.dartOutputs, writer.writer);
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
      if (expectedWithConstConstructor.contains(definedClass.name.lexeme)) {
        final constructor = definedClass.members
            .whereType<ConstructorDeclaration>()
            .firstWhereOrNull((e) => e.name == null);
        if (constructor?.constKeyword == null) {
          matchState['desc'] = 'Constructor ${definedClass.name.lexeme} is not '
              'const.';
          return false;
        }

        remaining.remove(definedClass.name.lexeme);
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
