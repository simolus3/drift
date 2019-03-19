import 'package:test_core/src/executable.dart' as test;
import '../.dart_tool/build/entrypoint/build.dart' as builder;

void main() async {
  // Run the build runner
  await builder.main(['build', '--delete-conflicting-outputs']);
  // Run tests
  await test.main([]);
}