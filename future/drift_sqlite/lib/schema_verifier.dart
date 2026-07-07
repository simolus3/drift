/// This library exports helpers that can compare SQLite database schemas,
/// reporting detailed issues on schema mismatches.
///
/// This is intended as a debugging tool, allowing you to verify schema
/// migrations.
library;

export 'src/schema_verifier/common.dart' show ValidationOptions, SchemaMismatch;
export 'src/schema_verifier/verifier.dart';
export 'src/schema_verifier/verify_self.dart';
