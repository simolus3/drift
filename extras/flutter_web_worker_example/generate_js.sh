rm -f web/worker.dart.*
dart run build_runner build --delete-conflicting-outputs
cp -f .dart_tool/build/generated/flutter_web_worker_example/web/worker* web/
