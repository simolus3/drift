import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group(enforceEqualIterable, () {
    test('should accept 2 equal iterables', () {
      enforceEqualIterable(
        [
          NotNull('foo'),
        ],
        [
          NotNull('foo'),
        ],
      );
    });

    test('should throw if only first is empty', () {
      expect(
        () => enforceEqualIterable(
          [],
          [
            NotNull('foo'),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw if only second is empty', () {
      expect(
        () => enforceEqualIterable(
          [
            NotNull('foo'),
          ],
          [],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw if first is shorter', () {
      expect(
        () => enforceEqualIterable(
          [
            NotNull('foo'),
          ],
          [
            NotNull('foo'),
            UniqueColumn('foo', null),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw if second is shorter', () {
      expect(
        () => enforceEqualIterable(
          [
            NotNull('foo'),
            UniqueColumn('foo', null),
          ],
          [
            NotNull('foo'),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
