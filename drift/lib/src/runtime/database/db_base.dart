import 'package:meta/meta.dart';

import '../../connections/connection.dart';
import '../../query_builder/schema/entities.dart';
import '../streams/update_rules.dart';
import 'connection_compat.dart';
import 'connection_user.dart';

abstract base class GeneratedDatabase extends DatabaseConnectionUser {
  /// The used drift database implementation responsible for building queries
  /// and executing them.
  final DriftDatabaseImplementation implementation;
  Future<DriftSession>? _openingSession;

  /// Opens a drift database backed by a given [implementation].
  GeneratedDatabase(this.implementation);

  /// Specify the schema version of your database. Whenever you change or add
  /// tables, you should bump this field and provide a [migration] strategy.
  ///
  /// The [schemaVersion] must be positive. Typically, one starts with a value
  /// of `1` and increments the value for each modification to the schema.
  int get schemaVersion;

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

  // TODO: Migrations

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
        // TODO: Migrations, before-open callback
        return DriftCompatibilitySession(
          inner: await implementation.open(),
          dialect: implementation.dialect,
        );
      });
    }
  }

  /// Closes this drift database and releases associated resources.
  Future<void> close() async {}
}
