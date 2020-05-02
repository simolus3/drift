import 'package:sqlparser/src/reader/tokenizer/utils.dart';
import 'package:test/test.dart';

void main() {
  test('isDigit', () {
    expect(isDigit('0'.codeUnitAt(0)), isTrue);
    expect(isDigit('3'.codeUnitAt(0)), isTrue);
    expect(isDigit('9'.codeUnitAt(0)), isTrue);

    expect(isDigit('a'.codeUnitAt(0)), isFalse);
    expect(isDigit('x'.codeUnitAt(0)), isFalse);
  });

  test('isHexDigit', () {
    expect(isHexDigit('0'.codeUnitAt(0)), isTrue);
    expect(isHexDigit('3'.codeUnitAt(0)), isTrue);
    expect(isHexDigit('9'.codeUnitAt(0)), isTrue);
    expect(isHexDigit('a'.codeUnitAt(0)), isTrue);
    expect(isHexDigit('C'.codeUnitAt(0)), isTrue);
    expect(isHexDigit('F'.codeUnitAt(0)), isTrue);

    expect(isDigit('x'.codeUnitAt(0)), isFalse);
    expect(isDigit('G'.codeUnitAt(0)), isFalse);
  });

  test('canStartIdentifier', () {
    expect(canStartIdentifier('_'.codeUnitAt(0)), isTrue);
    expect(canStartIdentifier('a'.codeUnitAt(0)), isTrue);
    expect(canStartIdentifier('C'.codeUnitAt(0)), isTrue);
    expect(canStartIdentifier('Z'.codeUnitAt(0)), isTrue);

    expect(canStartIdentifier('['.codeUnitAt(0)), isFalse);
    expect(canStartIdentifier('0'.codeUnitAt(0)), isFalse);
  });

  test('continuesIdentifier', () {
    expect(continuesIdentifier('_'.codeUnitAt(0)), isTrue);
    expect(continuesIdentifier('a'.codeUnitAt(0)), isTrue);
    expect(continuesIdentifier('Z'.codeUnitAt(0)), isTrue);
    expect(continuesIdentifier('0'.codeUnitAt(0)), isTrue);

    expect(continuesIdentifier('['.codeUnitAt(0)), isFalse);
  });
}
