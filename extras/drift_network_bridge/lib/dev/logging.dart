import 'dart:io';

void kDebugPrint(dynamic message) {
  if (!bool.fromEnvironment('dart.vm.profile') && !bool.fromEnvironment('dart.vm.product')) {
    print(message);
  }
}

bool kIsTestEnv = Platform.environment.containsKey('FLUTTER_TEST');
