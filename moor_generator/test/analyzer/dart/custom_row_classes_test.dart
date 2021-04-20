// @dart=2.9
@Tags(['analyzer'])
import 'package:moor_generator/src/analyzer/errors.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  TestState state;

  setUpAll(() {
    state = TestState.withContent({
      'a|lib/invalid_no_unnamed_constructor.dart': '''
import 'package:moor/moor.dart';

class RowClass {
  RowClass.create();
}
@UseRowClass(RowClass)
class TableClass extends Table {}
      ''',
      'a|lib/mismatching_type.dart': '''
import 'package:moor/moor.dart';

class RowClass {
  RowClass(int x);
}
@UseRowClass(RowClass)
class TableClass extends Table {
  TextColumn get x => text()();
}
      ''',
      'a|lib/mismatching_nullability.dart': '''
import 'package:moor/moor.dart';

class RowClass {
  RowClass(int x);
}
@UseRowClass(RowClass)
class TableClass extends Table {
  IntColumn get x => integer().nullable()();
}
      ''',
      'a|lib/mismatching_type_converter.dart': '''
import 'package:moor/moor.dart';

class MyConverter extends TypeConverter<int, String> {
  const MyConverter();

  @override
  int? mapToDart(String? fromDb) => throw 'stub';
  @override
  String? mapToSql(int? value) => throw 'stub';
}

class RowClass {
  RowClass(String x);
}

@UseRowClass(RowClass)
class TableClass extends Table {
  TextColumn get x => text().map(const MyConverter())();
}
      ''',
    });
  });

  tearDownAll(() => state.close());

  group('warns about misuse', () {
    test('when the desired row class does not have an unnamed constructor',
        () async {
      final file =
          await state.analyze('package:a/invalid_no_unnamed_constructor.dart');
      expect(
        file.errors.errors,
        contains(isA<ErrorInDartCode>().having((e) => e.message, 'message',
            contains('must have an unnamed constructor'))),
      );
    });

    test('when a parameter has a mismatching type', () async {
      final file = await state.analyze('package:a/mismatching_type.dart');
      expect(
        file.errors.errors,
        contains(isA<ErrorInDartCode>().having((e) => e.message, 'message',
            contains('Invalid type, expected String'))),
      );
    });

    test('when a parameter should be nullable', () async {
      final file =
          await state.analyze('package:a/mismatching_nullability.dart');
      expect(
        file.errors.errors,
        contains(isA<ErrorInDartCode>().having((e) => e.message, 'message',
            'Expected this parameter to be nullable')),
      );
    });

    test('when a parameter has a mismatching type converter', () async {
      final file =
          await state.analyze('package:a/mismatching_type_converter.dart');
      expect(
        file.errors.errors,
        contains(isA<ErrorInDartCode>()
            .having((e) => e.message, 'message', 'Parameter must accept int')),
      );
    });
  });
}
