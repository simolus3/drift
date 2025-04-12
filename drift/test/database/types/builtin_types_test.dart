import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/dialect/postgres.dart';
import 'package:drift/dialect/sqlite.dart';
import 'package:drift/drift.dart';
import 'package:test/test.dart';

void main() {
  const dialects = [
    ('sqlite', SqliteDialect()),
    ('postgres', PostgresDialect())
  ];

  for (final (name, dialect) in dialects) {
    group('dialect $name', () {
      group('blobs', () {
        const type = BuiltinDriftType.byteArray;

        test('maps without transformation', () {
          final data = Uint8List.fromList(List.generate(256, (i) => i));

          expect(type.sqlParameter(dialect, data), data);
          expect(type.dartValue(dialect, data), data);
        });

        test('writes blob literals', () {
          const hex = '67656E6572616C206B656E6F626921';
          final data = Uint8List.fromList(utf8.encode('general kenobi!'));

          expect(type.sqlLiteral(dialect, data), equalsIgnoringCase("x'$hex'"));
        });

        test('maps of string', () {
          const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz';

          final data = List.generate(256, (i) => chars[i % chars.length]);
          final dataString = data.join();
          final dataInt = data.map((e) => e.codeUnits[0]).toList();
          final dataUint8 = Uint8List.fromList(dataInt);
          expect(type.dartValue(dialect, dataString), dataUint8);
        });
      });
    });
  }

  group('bool type', () {
    const type = BuiltinDriftType.bool;
    const sqlite = SqliteDialect();
    const postgres = PostgresDialect();

    test('Can read booleans from sqlite', () {
      expect(type.dartValue(sqlite, 1), true);
      expect(type.dartValue(sqlite, 0), false);
    });

    test('Can read booleans from postgres', () {
      expect(type.dartValue(postgres, true), true);
      expect(type.dartValue(postgres, false), false);
    });

    test('Can be mapped to sqlite constant', () {
      expect(type.sqlLiteral(sqlite, true), '1');
      expect(type.sqlLiteral(sqlite, false), '0');
    });

    test('Can be mapped to postgres constant', () {
      expect(type.sqlLiteral(postgres, true), 'true');
      expect(type.sqlLiteral(postgres, false), 'false');
    });

    test('Can be mapped to sqlite variable', () {
      expect(type.sqlParameter(sqlite, true), 1);
      expect(type.sqlParameter(sqlite, false), 0);
    });

    test('Can be mapped to postgres variable', () {
      expect(type.sqlParameter(postgres, true), true);
      expect(type.sqlParameter(postgres, false), false);
    });
  });
}
