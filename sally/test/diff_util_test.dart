import 'package:test_api/test_api.dart';
import 'package:sally/diff_util.dart';

List<T> applyEditScript<T>(List<T> a, List<T> b, List<EditAction> actions) {
  final copy = List.of(a);

  for (var action in actions) {
    if (action.isDelete) {
      final deleteStartIndex = action.index;
      copy.removeRange(deleteStartIndex, deleteStartIndex + action.amount);
    } else {
      final toAdd = b.getRange(action.indexFromOther, action.indexFromOther + action.amount);
      copy.insertAll(action.index, toAdd);
    }
  }

  return copy;
}

void main() {
  final a  = ['a', 'b', 'c', 'a', 'b', 'b', 'a'];
  final b = ['c', 'b', 'a', 'b', 'a', 'c'];

  test('diff matcher should produce a correct edit script', () {
    expect(applyEditScript(a, b, diff(a, b)), b);
  });
}