// #docregion setup
import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:postgres/postgres.dart';

part 'postgres.g.dart';

class Users extends Table {
  UuidColumn get id => customType(PgTypes.uuid).withDefault(genRandomUuid())();
  TextColumn get name => text()();
  Column<PgDate> get birthDate => customType(PgTypes.date).nullable()();
}

@DriftDatabase(tables: [Users])
class MyDatabase extends _$MyDatabase {
  MyDatabase(super.e);

  @override
  int get schemaVersion => 1;
}

void main() async {
  final pgDatabase = PgDatabase(
    endpoint: Endpoint(
      host: 'localhost',
      database: 'postgres',
      username: 'postgres',
      password: 'postgres',
    ),
    settings: ConnectionSettings(
      // If you expect to talk to a Postgres database over a public connection,
      // please use SslMode.verifyFull instead.
      sslMode: SslMode.disable,
    ),
  );

  final driftDatabase = MyDatabase(pgDatabase);

  // Insert a new user
  await driftDatabase.users.insertOne(UsersCompanion.insert(name: 'Simon'));

  // Print all of them
  print(await driftDatabase.users.all().get());

  await driftDatabase.close();
}
// #enddocregion setup

List<Endpoint> get yourListOfEndpoints => throw 'stub';

// #docregion pool
Future<void> openWithPool() async {
  final pool = Pool.withEndpoints(yourListOfEndpoints);

  final driftDatabase = MyDatabase(PgDatabase.opened(pool));
  await driftDatabase.users.select().get();

  // Note that PgDatabase.opened() doesn't close the underlying connection when
  // the drift database is closed.
  await driftDatabase.close();
  await pool.close();
}
// #enddocregion pool

// #docregion time
// This table uses proper postgres types to store date/time values.
class TimeStore extends Table {
  Column<PgDate> get date => customType(PgTypes.date)();
  Column<PgDateTime> get timestampWithTimezone =>
      customType(PgTypes.timestampWithTimezone)();
  Column<PgDateTime> get timestampWithoutTimezone =>
      customType(PgTypes.timestampNoTimezone)();
  Column<Interval> get interval => customType(PgTypes.interval)();
}
// #enddocregion time

// #docregion time-dialectaware
class _DialectAwareDateTimeType implements DialectAwareSqlType<PgDateTime> {
  /// The underlying type used when this dialect-aware type is used on postgres
  /// databases.
  static const _postgres = PgTypes.timestampWithTimezone;

  /// The fallback type used when we're not talking to postgres.
  static const _other = DriftSqlType.dateTime;

  const _DialectAwareDateTimeType();

  @override
  String mapToSqlLiteral(GenerationContext context, PgDateTime dartValue) {
    return switch (context.dialect) {
      SqlDialect.postgres => _postgres.mapToSqlLiteral(dartValue),
      _ => context.typeMapping.mapToSqlLiteral(dartValue.dateTime),
    };
  }

  @override
  Object mapToSqlParameter(GenerationContext context, PgDateTime dartValue) {
    return switch (context.dialect) {
      SqlDialect.postgres => _postgres.mapToSqlParameter(dartValue),
      _ => context.typeMapping.mapToSqlVariable(dartValue.dateTime)!,
    };
  }

  @override
  PgDateTime read(SqlTypes typeSystem, Object fromSql) {
    return switch (typeSystem.dialect) {
      SqlDialect.postgres => _postgres.read(fromSql),
      _ => PgDateTime(typeSystem.read(_other, fromSql)!),
    };
  }

  @override
  String sqlTypeName(GenerationContext context) {
    return switch (context.dialect) {
      SqlDialect.postgres => _postgres.sqlTypeName(context),
      _ => _other.sqlTypeName(context),
    };
  }
}

const dateTime = _DialectAwareDateTimeType();

class DialectAwareTime extends Table {
  // This will use `timestamp with timezone` on postgres, and fall back to the
  // default date type (integer or text) on sqlite databases.
  Column<PgDateTime> get timeValue => customType(dateTime)();
}

// #enddocregion time-dialectaware
