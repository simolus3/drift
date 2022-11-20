/// Internal library used by generated code when drift's modular code generation
/// is enabled.
///
/// This library is not part of drift's public API and should not be imported
/// manually.
library drift.internal.modules;

import 'package:drift/drift.dart';

final _databaseElementCache = Expando<_DatabaseElementCache>();

/// A database accessor implicitly created by a `.drift` file.
///
/// When modular code generation is enabled, drift will emit a file with a
/// [ModularAccessor] for each drift file instead of generating all the code for
/// a database into a single file.
class ModularAccessor extends DatabaseAccessor<GeneratedDatabase> {
  /// Default constructor - create an accessor from the [attachedDatabase].
  ModularAccessor(super.attachedDatabase);

  /// Find a result set by its [name] in the database. The result is cached.
  T resultSet<T extends ResultSetImplementation>(String name) {
    return attachedDatabase.resultSet(name);
  }

  /// Find an accessor type, or create it with [create]. The result will be
  /// cached.
  T accessor<T extends DatabaseAccessor>(T Function(GeneratedDatabase) create) {
    return attachedDatabase.accessor<T>(create);
  }
}

/// Look up cached elements or accessors from a database.
/// This extension is meant to be used by drift-generated code.
extension ReadDatabaseContainer on GeneratedDatabase {
  _DatabaseElementCache get _cache {
    return _databaseElementCache[attachedDatabase] ??=
        _DatabaseElementCache(attachedDatabase);
  }

  /// Find a result set by its [name] in the database. The result is cached.
  T resultSet<T extends ResultSetImplementation>(String name) {
    return _cache.knownEntities[name]! as T;
  }

  /// Find an accessor by its [name] in the database, or create it with
  /// [create]. The result will be cached.
  T accessor<T extends DatabaseAccessor>(T Function(GeneratedDatabase) create) {
    final cache = _cache.knownAccessors;

    return cache.putIfAbsent(T, () => create(attachedDatabase)) as T;
  }
}

class _DatabaseElementCache {
  final Map<String, DatabaseSchemaEntity> knownEntities;
  final Map<Type, DatabaseAccessor> knownAccessors = {};

  _DatabaseElementCache(GeneratedDatabase database)
      : knownEntities = {
          for (final entity in database.allSchemaEntities)
            entity.entityName: entity
        };
}
