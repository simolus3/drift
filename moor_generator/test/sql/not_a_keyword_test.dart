import 'package:moor_generator/src/sql/parser/grammar/not_a_keyword.dart';
import 'package:test_api/test_api.dart';

final parser = NotAKeywordParser();
final withTrim = parser.trim();

void main() {
  test('does not accept sqlite keywords', () {
    expect(parser.parse('SELECT').isSuccess, isFalse);
    expect(parser.parse('USING').isSuccess, isFalse);
    expect(withTrim.parse(' PRAGMA ').isSuccess, isFalse);
  });

  test('does accept words that are not sqlite keywords', () {
    expect(parser.parse('users').isSuccess, isTrue);
    expect(parser.parse('is_awesome').isSuccess, isTrue);
  });
}
