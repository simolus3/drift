import 'package:moor_ffi/database.dart';
import 'package:test/test.dart';

void main() {
  test('can bind and retreive 64 bit ints', () {
    const value = 1 << 62;

    final opened = Database.memory();
    final stmt = opened.prepare('SELECT ?');

    final result = stmt.select([value]);
    expect(result, [
      {'?': value}
    ]);

    opened.close();
  });
}
