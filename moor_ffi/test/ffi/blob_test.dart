import 'package:moor/moor.dart';
import 'package:moor_ffi/src/ffi/blob.dart';
import 'package:test/test.dart';

void main() {
  test('utf8 store and load test', () {
    final content = 'Hasta Mañana';
    final blob = CBlob.allocateString(content);

    expect(blob.load<CBlob>().readString(), content);
    blob.free();
  });

  test('blob load and store test', () {
    final data = List.generate(256, (x) => x);
    final blob = CBlob.allocate(Uint8List.fromList(data));

    expect(blob.load<CBlob>().read(256), data);
    blob.free();
  });
}
