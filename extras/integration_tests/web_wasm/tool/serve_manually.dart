import 'package:web_wasm/driver.dart';

void main() async {
  await TestAssetServer.start(fixedPort: 8080);
  print('Serving on http://localhost:8080/');
}
