import 'package:analyzer/dart/ast/token.dart';
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
///  - appending a `$` if the name is a reserved Dart keyword (e.g. `class`),
///    which cannot be used as an identifier on its own.
///
/// This transformation may map distinct SQL identifiers to the same Dart name
/// (e.g. `dartNameForSqlColumn('1a') == dartNameForSqlColumn('2a')`). To
/// generate unique names, this function can append numbers to the generated
/// identifier to make them unique. To make use of that, pass an iterable of
/// names already taken in [existingNames].
String dartNameForSqlColumn(
  String name, {
  Iterable<String> existingNames = const Iterable.empty(),
}) {
  // remove chars which cannot appear in dart identifiers, also strip away
  // leading digits
  var escapedName = name
      .replaceAll(_illegalChars, '')
      .replaceFirst(_leadingDigits, '');

  if (escapedName.isEmpty) {
    escapedName = 'empty';
  }

  escapedName = ReCase(escapedName).camelCase;

  // A reserved keyword like `class` is not a valid Dart identifier, so it can't
  // be used as a getter, field or parameter name. Append a `$` to make it one.
  if (Keyword.keywords[escapedName]?.isReservedWord ?? false) {
    escapedName = '$escapedName\$';
  }

  final potentialAmbiguousName = escapedName;
  var counter = 1;
  while (existingNames.contains(escapedName)) {
    escapedName = potentialAmbiguousName + counter.toString();
    counter++;
  }
  return escapedName;
}
