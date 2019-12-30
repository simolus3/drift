import 'package:test/test.dart';
import 'package:moor_ffi/open_helper.dart';

void main() {
  tearDown(open.reset);

  test('opening behavior can be overridden', () {
    var called = false;
    open.overrideFor(open.os, () {
      called = true;
      return null;
    });

    expect(open.openSqlite(), isNull);
    expect(called, isTrue);
  });
}
