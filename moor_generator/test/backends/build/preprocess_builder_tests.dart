//@dart=2.9
@Tags(['analyzer'])
import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:moor_generator/src/backends/build/preprocess_builder.dart';
import 'package:test/test.dart';

void main() {
  test('writes types from expressions in moor files', () async {
    final writer = InMemoryAssetWriter();
    final reader = await PackageAssetReader.currentIsolate();

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
import 'package:moor/moor.dart';

class MyConverter extends TypeConverter<DateTime, int> {
  const MyConverter();
  
  int mapToSql(DateTime time) => time?.millisecondsSinceEpoch;
  
  DateTime mapToDart(int fromSql) {
    if (fromSql == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(fromSql);
  }
}
        ''',
      },
      writer: writer,
      reader: reader,
    );

    final output =
        utf8.decode(writer.assets[AssetId.parse('foo|main.dart_in_moor')]);
    final serialized = json.decode(output);

    expect(serialized['const MyConverter()'], {
      'type': 'interface',
      'library': 'asset:foo/converter.dart',
      'class_name': 'MyConverter',
      'type_args': [],
    });
  });

  test('finds dart files over transitive imports', () async {
    final writer = InMemoryAssetWriter();
    final reader = await PackageAssetReader.currentIsolate();

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
import 'package:moor/moor.dart';

class MyConverter extends TypeConverter<DateTime, int> {
  const MyConverter();

  int mapToSql(DateTime time) => time?.millisecondsSinceEpoch;

  DateTime mapToDart(int fromSql) {
    if (fromSql == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(fromSql);
  }
}
        ''',
      },
      writer: writer,
      reader: reader,
    );

    final output =
        utf8.decode(writer.assets[AssetId.parse('foo|main.dart_in_moor')]);
    final serialized = json.decode(output);

    expect(serialized['const MyConverter()'], {
      'type': 'interface',
      'library': 'asset:foo/converter.dart',
      'class_name': 'MyConverter',
      'type_args': [],
    });
  });
}
