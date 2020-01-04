import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/analysis/types2/types.dart';
import 'package:test/test.dart';

class _FakeTypeable implements Typeable {}

void main() {
  test('copies types for a CopyTypeFrom relation', () {
    final first = _FakeTypeable();
    final second = _FakeTypeable();

    final graph = TypeGraph();
    graph[first] = const ResolvedType.bool();
    graph.addRelation(CopyTypeFrom(second, first));
    graph.performResolve();

    expect(graph[second], const ResolvedType.bool());
  });
}
