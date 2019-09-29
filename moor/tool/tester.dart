import 'package:test_core/src/executable.dart' as test;

void main() async {
  print('inside test file');
  // Run tests
  await test.main([]);
  print('done, script should terminate after coverage is collected');
}
