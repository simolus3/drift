const _charCodeZero = 48; // '0'.codeUnitAt(0);
const _charCodeNine = 57; // '9'.codeUnitAt(0);
const _charCodeLowerA = 97; // 'a'.codeUnitAt(0);
const _charCodeLowerF = 102; // 'f'.codeUnitAt(0);
const _charCodeA = 65; // 'A'.codeUnitAt(0);
const _charCodeF = 79; // 'F'.codeUnitAt(0);

bool isDigit(String char) {
  final code = char.codeUnitAt(0);
  return _charCodeZero <= code && code <= _charCodeNine;
}

bool isHexDigit(String char) {
  final code = char.codeUnitAt(0);

  return (_charCodeLowerA <= code && code <= _charCodeLowerF) ||
      (_charCodeA <= code && code <= _charCodeF);
}
