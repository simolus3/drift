const charTab = 9; // \t
const charLineFeed = 10; // \n
const charCarriageReturn = 13; // \r
const charSpace = 32;
const charExclMark = 33; // !
const charDoubleTick = 34; // "
const charDollarSign = 36;
const charPercent = 37; // %
const charAmpersand = 38; // &
const charSingleTick = 39; // '
const charParenLeft = 40; // (
const charParenRight = 41; // )
const charStar = 42; // *
const charPlus = 43; // +
const charComma = 44; // ,
const charMinus = 45; // -
const charPeriod = 46; // .
const charSlash = 47; // /
const charCodeZero = 48; // '0'.codeUnitAt(0);
const charCodeNine = 57; // '9'.codeUnitAt(0);
const charColon = 58; // :
const charSemicolon = 59; // ;
const charLess = 60; // <
const charEquals = 61; // =
const charGreater = 62; // >
const charQuestionMark = 63; // ?
const charAt = 64; // @
const charCodeA = 65; // 'A'.codeUnitAt(0);
const charCodeE = 69; // E
const charCodeF = 70; // 'F'.codeUnitAt(0);
const charCodeUnderscore = 95; // '_'.codeUnitAt(0);
const charCodeLowerA = 97; // 'a'.codeUnitAt(0);
const charCodeLowerF = 102; // 'f'.codeUnitAt(0);
const charCodeX = 88; // X
const charCodeZ = 90; // 'Z'.codeUnitAt(0);
const charBacktick = 96;
const charLowerE = 101;
const charCodeLowerX = 120; // x
const charCodeLowerZ = 122; // 'z'.codeUnitAt(0);
const charPipe = 124; // |
const charTilde = 126; // ~

bool isDigit(int charCode) {
  return charCodeZero <= charCode && charCode <= charCodeNine;
}

bool isHexDigit(int charCode) {
  return (charCodeLowerA <= charCode && charCode <= charCodeLowerF) ||
      (charCodeA <= charCode && charCode <= charCodeF) ||
      (charCodeZero <= charCode && charCode <= charCodeNine);
}

bool canStartColumnName(int charCode) {
  return charCode == charCodeUnderscore ||
      (charCodeLowerA <= charCode && charCode <= charCodeLowerZ) ||
      (charCodeA <= charCode && charCode <= charCodeZ);
}

bool continuesColumnName(int charCode) {
  return canStartColumnName(charCode) || isDigit(charCode);
}
