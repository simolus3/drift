@Tags(['analyzer'])
library;

import 'dart:convert';

import 'package:build_test/build_test.dart';
import 'package:drift_dev/src/backends/build/preprocess_builder.dart';
import 'package:test/test.dart';

import '../../utils.dart';

void main() {
  test('writes types from expressions in moor files', () async {
    final env = await driftTestEnvironment(rootPackage: 'foo');

    await testBuilder(
      PreprocessBuilder(),
      {
        'foo|main.moor': '''
import 'converter.dart';
--import 'package:moor_converters/converters.dart';

CREATE TABLE foo (
  id INT NOT NULL MAPPED BY `const MyConverter()`
);
        ''',
        'foo|converter.dart': '''
import 'package:drift/drift.dart';

class MyConverter extends TypeConverter<DateTime, int> {
  const MyConverter();

  int toSql(DateTime time) => time?.millisecondsSinceEpoch;

  DateTime fromSql(int fromSql) {
    if (fromSql == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(fromSql);
  }
}
        ''',
      },
      readerWriter: env,
    );

    final output = env.readGenerated('foo|main.drift_prep.json');
    final serialized = json.decode(output);

    expect(serialized['const MyConverter()'], {
      'type': 'interface',
      'library': 'asset:foo/converter.dart',
      'class_name': 'MyConverter',
      'type_args': [],
    });
  });

  test('finds dart files over transitive imports', () async {
    final env = await driftTestEnvironment(rootPackage: 'foo');

    await testBuilder(
      PreprocessBuilder(),
      {
        'foo|main.moor': '''
import 'indirection.moor';

CREATE TABLE foo (
  id INT NOT NULL MAPPED BY `const MyConverter()`
);
        ''',
        'foo|indirection.moor': '''
import 'converter.dart';
        ''',
        'foo|converter.dart': '''
import 'package:drift/drift.dart';

class MyConverter extends TypeConverter<DateTime, int> {
  const MyConverter();

  int toSql(DateTime time) => time?.millisecondsSinceEpoch;

  DateTime fromSql(int fromSql) {
    if (fromSql == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(fromSql);
  }
}
        ''',
      },
      readerWriter: env,
    );

    final output = env.readGenerated('foo|main.drift_prep.json');
    final serialized = json.decode(output);

    expect(serialized['const MyConverter()'], {
      'type': 'interface',
      'library': 'asset:foo/converter.dart',
      'class_name': 'MyConverter',
      'type_args': [],
    });
  });
}
