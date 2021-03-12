curl https://storage.googleapis.com/dart-archive/channels/stable/release/latest/linux_packages/dart_2.12.1-1_amd64.deb --output /tmp/dart.deb
dpkg -i /tmp/dart.deb

cd docs
dart pub get

if [[ -v BUILD_RELEASE ]]
then
  dart run build_runner build --release
  dart run build_runner build --release --output web:deploy
else
  dart run build_runner build
  dart run build_runner build --output web:deploy
fi

rm -r deploy/packages
