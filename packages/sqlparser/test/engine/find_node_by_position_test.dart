import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

void main() {
  test('finds the most relevant node', () {
    final engine = SqlEngine();
    final result = engine.parse('SELECT * FROM tbl;');
    //                                  | this is offset 8
    //                                         | this is offset 17

    final mostRelevantAtStar = result.findNodesAtPosition(8);
    expect(mostRelevantAtStar.length, 1);
    expect(mostRelevantAtStar.single, const TypeMatcher<StarResultColumn>());

    final mostRelevantAtTbl = result.findNodesAtPosition(17, length: 2);
    expect(mostRelevantAtTbl.length, 1);
    expect(mostRelevantAtTbl.single, const TypeMatcher<TableReference>());
  });
}
