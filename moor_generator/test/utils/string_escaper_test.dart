import 'package:moor_generator/src/utils/string_escaper.dart';
import 'package:test/test.dart';

void main() {
  test('creates Dart literals for values', () {
    const source = r'''
'$string$ \'
''';

    expect(asDartLiteral(source), '\'\\\'\\\$string\\\$ \\\\\\\'\\n\'');
    // This is a Dart literal representing a Dart literal, which makes things
    // complicated....             ↳ escaped ', start of literal
    //                               ↳ ' -> \' -> \\\' (escaped twice)
    //                                   ↳ $ -> \$ -> \\\$
    //                                                  ↳ \ -> \\ -> \\\\
    //                                                          NL -> \n -> \\n
  });
}
