import 'package:recase/recase.dart';

final _illegalChars = RegExp(r'[^0-9a-zA-Z_]');
final _leadingDigits = RegExp(r'^\d*');

/// Selects a valid Dart name for a column in SQL.
///
/// This includes:
///  - stripping leaading numbers and characters that can't appear in a Dart
///    identifier.
///  - defaulting to `empty` if a column only consists of invalid names.
///  - changing the case of the identifier to `camelCase`.
///
/// This transformation may map distinct SQL identifiers to the same Dart name
/// (e.g. `dartNameForSqlColumn('1a') == dartNameForSqlColumn('2a')`). To
/// generate unique names, this function can append numbers to the generated
/// identifier to make them unique. To make use of that, pass an iterable of
/// names already taken in [existingNames].
String dartNameForSqlColumn(String name,
    {Iterable<String> existingNames = const Iterable.empty()}) {
  // remove chars which cannot appear in dart identifiers, also strip away
  // leading digits
  var escapedName =
      name.replaceAll(_illegalChars, '').replaceFirst(_leadingDigits, '');

  if (escapedName.isEmpty) {
    escapedName = 'empty';
  }

  escapedName = ReCase(escapedName).camelCase;
  final potentialAmbiguousName = escapedName;
  var counter = 1;
  while (existingNames.contains(escapedName)) {
    escapedName = potentialAmbiguousName + counter.toString();
    counter++;
  }
  return escapedName;
}
