import 'package:sqlparser/src/reader/tokenizer/utils.dart';
import 'package:test/test.dart';

void main() {
  test('declared char constants are correct', () {
    const expected = {
      charTab: '\t',
      charLineFeed: '\n',
      charCarriageReturn: '\r',
      charSpace: ' ',
      charExclMark: '!',
      charDoubleTick: '"',
      charDollarSign: r'$',
      charPercent: '%',
      charAmpersand: '&',
      charSingleTick: "'",
      charParenLeft: '(',
      charParenRight: ')',
      charStar: '*',
      charPlus: '+',
      charComma: ',',
      charMinus: '-',
      charPeriod: '.',
      charSlash: '/',
      charCodeZero: '0',
      charCodeNine: '9',
      charColon: ':',
      charSemicolon: ';',
      charLess: '<',
      charEquals: '=',
      charGreater: '>',
      charQuestionMark: '?',
      charAt: '@',
      charCodeA: 'A',
      charCodeE: 'E',
      charCodeUnderscore: '_',
      charCodeLowerA: 'a',
      charCodeLowerF: 'f',
      charCodeF: 'F',
      charCodeX: 'X',
      charCodeZ: 'Z',
      charBacktick: '`',
      charLowerE: 'e',
      charCodeLowerX: 'x',
      charCodeLowerZ: 'z',
      charPipe: '|',
      charTilde: '~',
    };

    for (final testCase in expected.entries) {
      expect(testCase.key, testCase.value.codeUnitAt(0));
    }
  });

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

  test('canStartColumnName', () {
    expect(canStartColumnName('_'.codeUnitAt(0)), isTrue);
    expect(canStartColumnName('a'.codeUnitAt(0)), isTrue);
    expect(canStartColumnName('Z'.codeUnitAt(0)), isTrue);

    expect(canStartColumnName('['.codeUnitAt(0)), isFalse);
    expect(canStartColumnName('0'.codeUnitAt(0)), isFalse);
  });

  test('continuesColumnName', () {
    expect(continuesColumnName('_'.codeUnitAt(0)), isTrue);
    expect(continuesColumnName('a'.codeUnitAt(0)), isTrue);
    expect(continuesColumnName('Z'.codeUnitAt(0)), isTrue);
    expect(continuesColumnName('0'.codeUnitAt(0)), isTrue);

    expect(continuesColumnName('['.codeUnitAt(0)), isFalse);
  });
}
