import 'package:meta/meta.dart';

import '../../../sqlite3/dialect.dart';
import '../../query_builder.dart';
import 'shared.dart';

/// Deserializes a [DriftDialect] from the [rawDialect] representation obtained
/// by [serializeDialect].
@internal
DriftDialect deserializeDialect(JsonObject rawDialect) {
  DriftDialect dialect = const SqliteDialect();
  switch (rawDialect['dialect'] as String?) {
    case 'sqlite':
      final options = rawDialect['options'] as JsonObject;
      dialect = SqliteDialect(
        options: SqliteOptions(
          strictTablesByDefault: options['strict_tables_by_default'] as bool,
          storeDateTimesAsText: options['store_date_time_as_text'] as bool,
          useBinaryJsonRepresentation: options['use_binary_json'] as bool,
        ),
      );
  }

  return dialect;
}

/// Serializes the [dialect] if it's one of the known ones.
@internal
JsonObject serializeDialect(DriftDialect dialect) {
  final desc = <String, Object?>{
    'dialect': dialect.known?.name,
  };

  if (dialect case final SqliteDialect sqlite) {
    final options = sqlite.options;
    desc['options'] = {
      'strict_tables_by_default': options.strictTablesByDefault,
      'store_date_time_as_text': options.storeDateTimesAsText,
      'use_binary_json': options.useBinaryJsonRepresentation
    };
  }

  return desc;
}
