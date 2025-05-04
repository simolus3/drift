import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:drift/dialect/sqlite.dart';
import 'package:drift/drift.dart';
import 'package:sqlite3/common.dart';
import 'package:test/test.dart';

void main() {
  test('uses text json by default', () {
    const dialect = SqliteDialect();

    expect(BuiltinDriftType.json.typeName(dialect), 'TEXT');

    expect(
      BuiltinDriftType.json.sqlParameter(dialect, DatabaseJson({'foo': 'bar'})),
      json.encode({'foo': 'bar'}),
    );
    expect(
      BuiltinDriftType.json.sqlLiteral(dialect, DatabaseJson({'foo': 'bar'})),
      "'${json.encode({'foo': 'bar'})}'",
    );

    expect(BuiltinDriftType.json.dartValue(dialect, '[1, 2, 3]').dartValue,
        [1, 2, 3]);
  });

  test('can use binary representation', () {
    const dialect = SqliteDialect(
        options: SqliteOptions(useBinaryJsonRepresentation: true));

    expect(BuiltinDriftType.json.typeName(dialect), 'BLOB');

    expect(
      BuiltinDriftType.json.sqlParameter(dialect, DatabaseJson({'foo': 'bar'})),
      jsonb.encode({'foo': 'bar'}),
    );
    expect(
      BuiltinDriftType.json.sqlLiteral(dialect, DatabaseJson({'foo': 'bar'})),
      "x'${hex.encode(jsonb.encode({'foo': 'bar'}))}'",
    );

    expect(
      BuiltinDriftType.json
          .dartValue(dialect, jsonb.encode([1, 2, 3]))
          .dartValue,
      [1, 2, 3],
    );
  });
}
