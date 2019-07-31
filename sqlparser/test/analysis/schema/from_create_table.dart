import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../../common_data.dart';

const _affinityTests = {
  'INT': BasicType.int,
  'INTEGER': BasicType.int,
  'TINYINT': BasicType.int,
  'SMALLINT': BasicType.int,
  'MEDIUMINT': BasicType.int,
  'BIGINT': BasicType.int,
  'UNISGNED BIG INT': BasicType.int,
  'INT2': BasicType.int,
  'INT8': BasicType.int,
  'CHARACTER(20)': BasicType.text,
  'CHARACTER(255)': BasicType.text,
  'VARYING CHARACTER(255)': BasicType.text,
  'NCHAR(55)': BasicType.text,
  'NATIVE CHARACTER(70)': BasicType.text,
  'NVARCHAR(100)': BasicType.text,
  'TEXT': BasicType.text,
  'CLOB': BasicType.text,
  'BLOB': BasicType.blob,
  null: BasicType.blob,
  'REAL': BasicType.real,
  'DOUBLE': BasicType.real,
  'DOUBLE PRECISION': BasicType.real,
  'FLOAT': BasicType.real,
  'NUMERIC': BasicType.real,
  'DECIMAL(10,5)': BasicType.real,
  'BOOLEAN': BasicType.real,
  'DATE': BasicType.real,
  'DATETIME': BasicType.real,
};

void main() {
  test('affinity from typename', () {
    final resolver = SchemaFromCreateTable();

    _affinityTests.forEach((key, value) {
      expect(resolver.columnAffinity(key), equals(value),
          reason: '$key should have $value affinity');
    });
  });

  test('export table structure', () {
    final engine = SqlEngine();
    final stmt = engine.parse(createTableStmt).rootNode;

    final table = SchemaFromCreateTable().read(stmt as CreateTableStatement);

    expect(table.resolvedColumns.map((c) => c.name),
        ['id', 'email', 'score', 'display_name']);
    expect(table.resolvedColumns.map((c) => c.type), const [
      ResolvedType(type: BasicType.int),
      ResolvedType(type: BasicType.text),
      ResolvedType(type: BasicType.int),
      ResolvedType(type: BasicType.text, nullable: true),
    ]);

    expect(table.tableConstraints, hasLength(2));
  });
}
