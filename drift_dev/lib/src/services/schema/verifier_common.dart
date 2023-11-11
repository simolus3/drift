import 'find_differences.dart';

/// Attempts to recognize whether [name] is likely the name of an internal
/// sqlite3 table (like `sqlite3_sequence`) that we should not consider when
/// comparing schemas.
bool isInternalElement(String name, List<String> virtualTables) {
  // Skip sqlite-internal tables, https://www.sqlite.org/fileformat2.html#intschema
  if (name.startsWith('sqlite_')) return true;
  if (virtualTables.any((v) => name.startsWith('${v}_'))) return true;

  // This file is added on some Android versions when using the native Android
  // database APIs, https://github.com/simolus3/drift/discussions/2042
  if (name == 'android_metadata') return true;

  return false;
}

void verify(List<Input> referenceSchema, List<Input> actualSchema,
    bool validateDropped) {
  final result =
      FindSchemaDifferences(referenceSchema, actualSchema, validateDropped)
          .compare();

  if (!result.noChanges) {
    throw SchemaMismatch(result.describe());
  }
}

/// Thrown when the actual schema differs from the expected schema.
class SchemaMismatch implements Exception {
  final String explanation;

  SchemaMismatch(this.explanation);

  @override
  String toString() {
    return 'Schema does not match\n$explanation';
  }
}
