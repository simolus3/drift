import 'package:web_wasm/driver.dart';

void main() async {
  await TestAssetServer.start();
  print('Serving on http://localhost:8080/');
}
