import 'package:charcode/ascii.dart';

bool isDigit(int charCode) {
  return $0 <= charCode && charCode <= $9;
}

bool isHexDigit(int charCode) {
  return ($a <= charCode && charCode <= $f) ||
      ($A <= charCode && charCode <= $F) ||
      ($0 <= charCode && charCode <= $9);
}

int interpretHexDigit(int charCode) {
  return switch (charCode) {
    >= $a && <= $f => 10 + charCode - $a,
    >= $A && <= $F => 10 + charCode - $A,
    >= $0 && <= $9 => charCode - $0,
    _ => throw ArgumentError(),
  };
}

bool canStartIdentifier(int charCode) {
  return charCode == $_ ||
      ($a <= charCode && charCode <= $z) ||
      ($A <= charCode && charCode <= $Z);
}

bool continuesIdentifier(int charCode) {
  return canStartIdentifier(charCode) || isDigit(charCode);
}
