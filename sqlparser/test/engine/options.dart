import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

void main() {
  test('refuses to work with old sqlite versions', () {
    expect(() => EngineOptions(version: const SqliteVersion.v3(12)),
        throwsArgumentError);
  });

  test('refuses to work with unsupported new sqlite versions', () {
    expect(() => EngineOptions(version: const SqliteVersion.v3(99)),
        throwsArgumentError);
  });
}
