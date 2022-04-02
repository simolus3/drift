rm -f web/worker.dart.js
rm -f web/worker.dart.min.js
flutter pub run build_runner build --delete-conflicting-outputs -o web:build/web/
cp -f build/web/worker.dart.js web/worker.dart.js
rm -rf build/web
flutter pub run build_runner build --release --delete-conflicting-outputs -o web:build/web/
cp -f build/web/worker.dart.js web/worker.dart.min.js
rm -rf build/web
