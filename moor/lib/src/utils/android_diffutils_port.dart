// ignore_for_file: cascade_invocations

/*
This implementation is copied from the DiffUtil class of the android support
library, available at https://chromium.googlesource.com/android_tools/+/refs/heads/master/sdk/sources/android-25/android/support/v7/util/DiffUtil.java
It has the following license:
 * Copyright (C) 2016 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

class Snake {
  int x;
  int y;
  int size;
  bool removal;
  bool reverse;
}

class Range {
  int oldListStart, oldListEnd;
  int newListStart, newListEnd;

  Range.nullFields();
  Range(this.oldListStart, this.oldListEnd, this.newListStart, this.newListEnd);
}

class DiffInput<T> {
  final List<T> from;
  final List<T> to;
  final bool Function(T a, T b) equals;

  DiffInput(this.from, this.to, this.equals);

  bool areItemsTheSame(int fromPos, int toPos) {
    return equals(from[fromPos], to[toPos]);
  }
}

@Deprecated('Will be removed in moor 2.0')
List<Snake> calculateDiff(DiffInput input) {
  final oldSize = input.from.length;
  final newSize = input.to.length;

  final snakes = <Snake>[];
  final stack = <Range>[];

  stack.add(Range(0, oldSize, 0, newSize));

  final max = oldSize + newSize + (oldSize - newSize).abs();

  final forward = List<int>(max * 2);
  final backward = List<int>(max * 2);

  final rangePool = <Range>[];

  while (stack.isNotEmpty) {
    final range = stack.removeLast();
    final snake = _diffPartial(input, range.oldListStart, range.oldListEnd,
        range.newListStart, range.newListEnd, forward, backward, max);

    if (snake != null) {
      if (snake.size > 0) {
        snakes.add(snake);
      }

      // offset the snake to convert its coordinates from the Range's are to
      // global
      snake.x += range.oldListStart;
      snake.y += range.newListStart;

      // add new ranges for left and right
      final left =
          rangePool.isEmpty ? Range.nullFields() : rangePool.removeLast();
      left.oldListStart = range.oldListStart;
      left.newListStart = range.newListStart;
      if (snake.reverse) {
        left.oldListEnd = snake.x;
        left.newListEnd = snake.y;
      } else {
        if (snake.removal) {
          left.oldListEnd = snake.x - 1;
          left.newListEnd = snake.y;
        } else {
          left.oldListEnd = snake.x;
          left.newListEnd = snake.y - 1;
        }
      }
      stack.add(left);

      final right = range;
      if (snake.reverse) {
        if (snake.removal) {
          right.oldListStart = snake.x + snake.size + 1;
          right.newListStart = snake.y + snake.size;
        } else {
          right.oldListStart = snake.x + snake.size;
          right.newListStart = snake.y + snake.size + 1;
        }
      } else {
        right.oldListStart = snake.x + snake.size;
        right.newListStart = snake.y + snake.size;
      }
      stack.add(right);
    } else {
      rangePool.add(range);
    }
  }

  snakes.sort((a, b) {
    final cmpX = a.x - b.x;
    return cmpX == 0 ? a.y - b.y : cmpX;
  });

  // add root snake
  final first = snakes.isEmpty ? null : snakes.first;

  if (first == null || first.x != 0 || first.y != 0) {
    snakes.insert(
        0,
        Snake()
          ..x = 0
          ..y = 0
          ..removal = false
          ..size = 0
          ..reverse = false);
  }

  return snakes;
}

Snake _diffPartial(DiffInput input, int startOld, int endOld, int startNew,
    int endNew, List<int> forward, List<int> backward, int kOffset) {
  final oldSize = endOld - startOld;
  final newSize = endNew - startNew;

  if (endOld - startOld < 1 || endNew - startNew < 1) return null;

  final delta = oldSize - newSize;
  final dLimit = (oldSize + newSize + 1) ~/ 2;

  forward.fillRange(kOffset - dLimit - 1, kOffset + dLimit + 1, 0);
  backward.fillRange(
      kOffset - dLimit - 1 + delta, kOffset + dLimit + 1 + delta, oldSize);

  final checkInFwd = delta.isOdd;

  for (var d = 0; d <= dLimit; d++) {
    for (var k = -d; k <= d; k += 2) {
      // find forward path
      // we can reach k from k - 1 or k + 1. Check which one is further in the
      // graph.
      int x;
      bool removal;

      if (k == -d ||
          k != d && forward[kOffset + k - 1] < forward[kOffset + k + 1]) {
        x = forward[kOffset + k + 1];
        removal = false;
      } else {
        x = forward[kOffset + k - 1] + 1;
        removal = true;
      }

      // set y based on x
      var y = x - k;

      // move diagonal as long as items match
      while (x < oldSize &&
          y < newSize &&
          input.areItemsTheSame(startOld + x, startNew + y)) {
        x++;
        y++;
      }

      forward[kOffset + k] = x;

      if (checkInFwd && k >= delta - d + 1 && k <= delta + d - 1) {
        if (forward[kOffset + k] >= backward[kOffset + k]) {
          final outSnake = Snake()..x = backward[kOffset + k];
          outSnake
            ..y = outSnake.x - k
            ..size = forward[kOffset + k] - backward[kOffset + k]
            ..removal = removal
            ..reverse = false;

          return outSnake;
        }
      }
    }

    for (var k = -d; k <= d; k += 2) {
      // find reverse path at k + delta, in reverse
      final backwardK = k + delta;
      int x;
      bool removal;

      if (backwardK == d + delta ||
          backwardK != -d + delta &&
              backward[kOffset + backwardK - 1] <
                  backward[kOffset + backwardK + 1]) {
        x = backward[kOffset + backwardK - 1];
        removal = false;
      } else {
        x = backward[kOffset + backwardK + 1] - 1;
        removal = true;
      }

      // set y based on x
      var y = x - backwardK;
      // move diagonal as long as items match
      while (x > 0 &&
          y > 0 &&
          input.areItemsTheSame(startOld + x - 1, startNew + y - 1)) {
        x--;
        y--;
      }

      backward[kOffset + backwardK] = x;

      if (!checkInFwd && k + delta >= -d && k + delta <= d) {
        if (forward[kOffset + backwardK] >= backward[kOffset + backwardK]) {
          final outSnake = Snake()..x = backward[kOffset + backwardK];
          outSnake
            ..y = outSnake.x - backwardK
            ..size =
                forward[kOffset + backwardK] - backward[kOffset + backwardK]
            ..removal = removal
            ..reverse = true;

          return outSnake;
        }
      }
    }
  }

  throw StateError("Unexpected case: Please make sure the lists don't change "
      'during a diff');
}
