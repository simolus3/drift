import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

Map<String, ResolveResult> _types = {
  'SELECT * FROM demo WHERE id = ?':
      const ResolveResult(ResolvedType(type: BasicType.int)),
  'SELECT * FROM demo WHERE content = ?':
      const ResolveResult(ResolvedType(type: BasicType.text)),
  'SELECT * FROM demo LIMIT ?':
      const ResolveResult(ResolvedType(type: BasicType.int)),
};

void main() {
  final id = TableColumn('id', const ResolvedType(type: BasicType.int));
  final content =
      TableColumn('content', const ResolvedType(type: BasicType.text));

  final demoTable = Table(
    name: 'demo',
    resolvedColumns: [id, content],
  );

  _types.forEach((sql, resolvedType) {
    test('types: resolves in $sql', () {
      final engine = SqlEngine()..registerTable(demoTable);
      final content = engine.analyze(sql);

      final variable = content.root.allDescendants
          .firstWhere((node) => node is Variable) as Typeable;

      expect(content.typeOf(variable), equals(resolvedType));
    });
  });
}
