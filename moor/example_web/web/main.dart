import 'package:moor/moor_web.dart';

void main() async {
  final executor = AlaSqlDatabase('database');
  final result = await executor.doWhenOpened((e) {
    return e.runSelect('SELECT 1', const []);
  });
  print(result);
}
