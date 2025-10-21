import 'package:jaspr/jaspr.dart';
import 'package:riverpod/riverpod.dart';
import 'package:universal_web/web.dart' as web;

Future<String> determineDriftWasmCompatibility() async {
  throw UnsupportedError('Only runs on clients');
}

extension ResolveDomNode on BuildContext {
  web.Node get node => throw UnsupportedError('Only runs on clients');
}

Component searchModalImpl() {
  return const Component.empty();
}

ProviderContainer? get rootContainer => null;
