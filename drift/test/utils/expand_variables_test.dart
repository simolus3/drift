import 'package:drift/drift.dart' show $expandVar;
import 'package:test/test.dart';

void main() {
  test('\$expandVar test', () {
    expect($expandVar(4, 0), '');
    expect($expandVar(2, 3), '@2, @3, @4');
  });
}
