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
///  - appending a `$` if the name is one of the [reservedNames], e.g. because
///    it would conflict with a member of the class the column is generated
///    into (see [tableClassMemberNames]).
///
/// This transformation may map distinct SQL identifiers to the same Dart name
/// (e.g. `dartNameForSqlColumn('1a') == dartNameForSqlColumn('2a')`). To
/// generate unique names, this function can append numbers to the generated
/// identifier to make them unique. To make use of that, pass an iterable of
/// names already taken in [existingNames].
String dartNameForSqlColumn(
  String name, {
  Iterable<String> existingNames = const Iterable.empty(),
  Set<String> reservedNames = const {},
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
  // Names reserved by the caller (e.g. because they're already used by another
  // member of the generated class) are escaped the same way.
  if ((Keyword.keywords[escapedName]?.isReservedWord ?? false) ||
      reservedNames.contains(escapedName)) {
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

/// Returns the names of members that the class generated for a table defined
/// in SQL has in addition to the fields for its columns.
///
/// These classes extend drift's `Table` class and mix in `TableInfo` (or
/// `ResultSet` with the drift3 preview), so a column named like one of their
/// members (e.g. `text`, which is a method on `Table`) would conflict with that
/// member. Passing these names as `reservedNames` to [dartNameForSqlColumn]
/// avoids that.
Set<String> tableClassMemberNames({
  required bool drift3,
  required bool isVirtual,
}) {
  return {
    // Object
    'hashCode',
    'noSuchMethod',
    'runtimeType',
    'toString',
    // Table
    'blob',
    'boolean',
    'customConstraints',
    'customType',
    'dateTime',
    'dontWriteConstraints',
    'int64',
    'intEnum',
    'integer',
    'isStrict',
    'primaryKey',
    'real',
    'tableName',
    'text',
    'textEnum',
    'uniqueKeys',
    'withoutRowId',
    if (drift3) ...{
      // Table
      'col',
      'json',
      // ResultSet
      'alias',
      'aliasOrName',
      'asSelfType',
      'columns',
      'columnsByName',
      'createMapperFromPositions',
      'createMapperToDart',
      'entityName',
      'mapFromCompanion',
      'withAlias',
    } else ...{
      // Table
      'sqliteAny',
      // TableInfo
      'actualTableName',
      'aliasedName',
      'asDslTable',
      'attachedDatabase',
      'columnsByName',
      'createAlias',
      'entityName',
      'map',
      'mapFromCompanion',
      'validateIntegrity',
    },
    // VirtualTableInfo
    if (isVirtual) 'moduleAndArgs',
  };
}
