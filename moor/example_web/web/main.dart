import 'package:example_web/main.dart';
import 'package:flutter_web_ui/ui.dart' as ui;

void main() async {
  await ui.webOnlyInitializePlatform();
  launchApp();
}
