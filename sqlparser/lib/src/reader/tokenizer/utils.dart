import 'package:charcode/ascii.dart';

bool isDigit(int charCode) {
  return $0 <= charCode && charCode <= $9;
}

bool isHexDigit(int charCode) {
  return ($a <= charCode && charCode <= $f) ||
      ($A <= charCode && charCode <= $F) ||
      ($0 <= charCode && charCode <= $9);
}

bool canStartIdentifier(int charCode) {
  return charCode == $_ ||
      ($a <= charCode && charCode <= $z) ||
      ($A <= charCode && charCode <= $Z);
}

bool continuesIdentifier(int charCode) {
  return canStartIdentifier(charCode) || isDigit(charCode);
}
