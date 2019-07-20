import 'package:test_core/src/executable.dart' as test;
import '../.dart_tool/build/entrypoint/build.dart' as builder;

void main() async {
  print('inside test file');
  // Run the build runner
  await builder.main(['build', '--delete-conflicting-outputs']);
  print('done with build runner, now starting with tests');
  // Run tests
  await test.main([]);
  print('done, script should terminate after coverage is collected');
}
