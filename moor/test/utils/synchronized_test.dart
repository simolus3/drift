import 'package:moor/src/utils/synchronized.dart';
import 'package:test/test.dart';

void main() {
  test('synchronized runs code in sequence', () async {
    final lock = Lock();
    var i = 0;
    final completionOrder = <int>[];
    final futures = List.generate(
        100,
        (index) => lock.synchronized(() => i++)
          ..whenComplete(() => completionOrder.add(index)));
    final results = await Future.wait(futures);

    expect(results, List.generate(100, (index) => index));
    expect(completionOrder, List.generate(100, (index) => index));
  });
}
