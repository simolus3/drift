/// A utility library to find an edit script that turns a list into another.
/// This is useful when displaying a updating stream of immutable lists in a
/// list that can be updated.
library diff_util;

import 'package:sally/src/utils/android_diffutils_port.dart' as impl;

class EditAction {
  /// The index of the first list on which this action should be applied. If
  /// this action [isDelete], that index and the next [amount] indices should be
  /// deleted. Otherwise, this index should be moved back by [amount] and
  /// entries from the second list (starting at [indexFromOther]) should be
  /// inserted into the gap.
  final int index;

  /// The amount of entries affected by this action
  final int amount;

  /// If this action [isInsert], this is the first index from the second list
  /// from where the items should be taken from.
  final int indexFromOther;

  /// Whether this action should delete entries from the first list
  bool get isDelete => indexFromOther == null;

  /// Whether this action should insert entries into the first list
  bool get isInsert => indexFromOther != null;

  EditAction(this.index, this.amount, this.indexFromOther);

  @override
  String toString() {
    if (isDelete) {
      return 'EditAction: Delete $amount entries from the first list, starting '
          'at index $index';
    } else {
      return 'EditAction: Insert $amount entries into the first list, taking '
          'them from the second list starting at $indexFromOther. The entries '
          'should be written starting at index $index';
    }
  }
}

/// Finds the shortest edit script that turns list [a] into list [b].
/// The implementation is ported from androids DiffUtil, which in turn
/// implements a variation of Eugene W. Myer's difference algorithm. The
/// algorithm is optimized for space and uses O(n) space to find the minimal
/// number of addition and removal operations between the two lists. It has
/// O(N + D^2) time performance, where D is the minimum amount of edits needed
/// to turn a into b.
List<EditAction> diff<T>(List<T> a, List<T> b,
    {bool Function(T a, T b) equals}) {
  final defaultEquals = equals ?? (T a, T b) => a == b;
  final snakes = impl.calculateDiff(impl.DiffInput<T>(a, b, defaultEquals));
  final actions = <EditAction>[];

  var posOld = a.length;
  var posNew = b.length;
  for (var snake in snakes.reversed) {
    final snakeSize = snake.size;
    final endX = snake.x + snakeSize;
    final endY = snake.y + snakeSize;

    if (endX < posOld) {
      // starting (including) with index endX, delete posOld - endX chars from a
      actions.add(EditAction(endX, posOld - endX, null));
    }
    if (endY < posNew) {
      // starting with index endX, insert posNex - endY characters into a. The
      // characters should be taken from b, starting (including) at the index
      // endY. The char that was at index endX should be pushed back.
      actions.add(EditAction(endX, posNew - endY, endY));
    }

    posOld = snake.x;
    posNew = snake.y;
  }

  return actions;
}
