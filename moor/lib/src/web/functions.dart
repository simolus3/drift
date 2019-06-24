part of 'package:moor/moor_web.dart';

final functions = _alasql['fn'] as JsObject;

void _registerFunctions() {
  functions['strftime'] = allowInterop(_strftime);
}

int _strftime(String format, int i) {
  // todo properly implement this
  return DateTime.now().millisecondsSinceEpoch ~/ 1000;
}
