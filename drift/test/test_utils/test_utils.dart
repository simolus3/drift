import 'package:test/test.dart';

export 'database_stub.dart'
    if (dart.library.ffi) 'database_vm.dart'
    if (dart.library.js) 'database_web.dart';
export 'matchers.dart';
export 'mocks.dart';

Map<String, dynamic> needsAdaptionForWeb() {
  return const {
    'browser': Skip('TODO: This test needs adaptions to work on the web.')
  };
}
