import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

void main() {
  group('json with new type inference', () {
    final engine = SqlEngine(EngineOptions(
      enabledExtensions: const [Json1Extension()],
    ));
    // add user (name, phone) table
    final table = engine.schemaReader.read(
      engine.parse('CREATE TABLE user (name TEXT, phone TEXT)').rootNode
          as TableInducingStatement,
    );
    engine.registerTable(table);

    ResolveResult findResult(String expression) {
      final result = engine.analyze('SELECT $expression;');

      final select = result.root as SelectStatement;
      final column = select.resultSet.resolvedColumns!.single;

      return result.typeOf(column);
    }

    const resolvedString = ResolveResult(ResolvedType(type: BasicType.text));

    test('create json', () {
      expect(findResult("json('{}')"), resolvedString);
      expect(findResult("json_array('foo', 'bar')"), resolvedString);
      expect(findResult("json_insert('{}')"), resolvedString);
      expect(findResult("json_replace('{}')"), resolvedString);
      expect(findResult("json_set('{}')"), resolvedString);
      expect(findResult('json_object()'), resolvedString);
      expect(findResult("json_patch('{}', '{}')"), resolvedString);
      expect(findResult("json_remove('{}', '{}')"), resolvedString);
      expect(findResult("json_quote('foo')"), resolvedString);
      expect(findResult('json_group_array()'), resolvedString);
      expect(findResult('json_group_object()'), resolvedString);
    });

    test('json_type', () {
      expect(
        findResult("json_type('foo', 'bar')"),
        const ResolveResult(ResolvedType(type: BasicType.text, nullable: true)),
      );
    });

    test('json_valid', () {
      expect(
          findResult('json_valid()'), const ResolveResult(ResolvedType.bool()));
    });

    test('json_extract', () {
      expect(findResult('json_extract()'), const ResolveResult.unknown());
    });

    test('json_array_length', () {
      expect(
        findResult('json_array_length()'),
        const ResolveResult(ResolvedType(type: BasicType.int)),
      );
    });

    test('can use table-valued functions', () {
      final result = engine.analyze('''
SELECT DISTINCT user.name
  FROM user, json_each(user.phone)
 WHERE json_each.value LIKE '704-%';
    ''');

      expect(result.errors, isEmpty);
    });
  });
}
