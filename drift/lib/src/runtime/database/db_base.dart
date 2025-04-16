import 'dart:async';

import 'package:meta/meta.dart';

import '../../connections/connection.dart';
import '../../query_builder/schema/entities.dart';
import '../migrations.dart';
import '../streams/delayed_stream_queries.dart';
import '../streams/store.dart';
import '../streams/update_rules.dart';
import '../../connections/connection_compat.dart';
import 'connection_user.dart';

abstract base class GeneratedDatabase extends DatabaseConnectionUser {
  /// The used drift database implementation responsible for building queries
  /// and executing them.
  final DriftDatabaseImplementation implementation;
  Future<DriftSession>? _openingSession;

  final Completer<StreamQueryStore> _openedStreamQueries = Completer();
  late StreamQueryStore _streamQueryStore;

  /// Opens a drift database backed by a given [implementation].
  GeneratedDatabase(this.implementation) {
    _streamQueryStore = DelayedStreamQueryStore(_openedStreamQueries.future);
  }

  /// Specify the schema version of your database. Whenever you change or add
  /// tables, you should bump this field and provide a [migration] strategy.
  ///
  /// The [schemaVersion] must be positive. Typically, one starts with a value
  /// of `1` and increments the value for each modification to the schema.
  int get schemaVersion;

  /// Defines the migration strategy that will determine how to deal with an
  /// increasing [schemaVersion]. The default value only supports creating the
  /// database by creating all tables known in this database. When you have
  /// changes in your schema, you'll need a custom migration strategy to create
  /// the new tables or change the columns.
  MigrationStrategy get migration => MigrationStrategy();
  MigrationStrategy? _cachedMigration;
  MigrationStrategy get _resolvedMigration => _cachedMigration ??= migration;

  /// The collection of update rules contains information on how updates on
  /// tables result in other updates, for instance due to a trigger.
  ///
  /// There should be no need to overwrite this field, drift will generate an
  /// appropriate implementation automatically.
  StreamQueryUpdateRules get streamUpdateRules =>
      const StreamQueryUpdateRules.none();

  /// A list of all [DatabaseSchemaEntity] that are specified in this database.
  ///
  /// This contains all tables, views, triggers, indexes and other drift-
  /// specific entities that are also encoded as schema entities.
  Iterable<DatabaseSchemaEntity> get allSchemaEntities;

  @override
  GeneratedDatabase get attachedDatabase => this;

  /// The root [DriftSession] used as a connection for this database.
  ///
  /// This should never be used directly, use [currentSession] instead. Drift
  /// manages transactions with zones, and manually using the [rootConnection]
  /// in the transaction of a transaction can cause deadlocks.
  @internal
  Future<DriftSession> rootConnection() {
    if (_openingSession case final opening?) {
      return opening;
    } else {
      return _openingSession = Future(() async {
        final (inner, streams) = await implementation.open();
        _openedStreamQueries.complete(streams);

        // Run migrations in a scoped connection zone so that they can use the
        // database while calls outside of migrations are waiting on this future
        // to complete.
        if (inner.root case final root?) {
          await runConnectionZoned(
            inner,
            streams,
            () => _runMigrations(root),
          );
        }

        return DriftCompatibilitySession(
          inner: inner,
          dialect: implementation.dialect,
        );
      });
    }
  }

  Future<void> _runMigrations(DriftRootSession session) async {
    final oldVersion = await session.schemaVersion;
    final strategy = _resolvedMigration;
    final migrator = Migrator(this);

    if (oldVersion == 0) {
      await strategy.onCreate(migrator);
      await session.writeSchemaVersion(schemaVersion);
    } else if (oldVersion < schemaVersion) {
      await strategy.onUpgrade(migrator, oldVersion, schemaVersion);
      await session.writeSchemaVersion(schemaVersion);
    }

    await strategy.beforeOpen?.call(
        OpeningDetails(oldVersion == 0 ? null : oldVersion, schemaVersion));
  }

  /// Creates a [Migrator] instance useful for running schema-altering
  /// statements against this database.
  Migrator createMigrator() => Migrator(this);

  /// Closes this drift database and releases associated resources.
  Future<void> close() async {
    if (_openingSession case final opening?) {
      final resolved = await opening;

      await resolved.close();
      await _streamQueryStore.close();
    }
  }
}

@internal
extension InternalGeneratedDatabase on GeneratedDatabase {
  StreamQueryStore get rootStreamQueries => _streamQueryStore;
}
