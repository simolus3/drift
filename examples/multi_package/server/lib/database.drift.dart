// dart format width=80
// ignore_for_file: type=lint
import 'package:drift3_preview/drift.dart' as i0;
import 'package:shared/src/users.drift.dart' as i1;
import 'package:shared/src/posts.drift.dart' as i2;
import 'package:server/database.drift.dart' as i3;
import 'package:drift_postgres/drift_postgres.dart' as i4;
import 'package:shared/shared.drift.dart' as i5;
import 'package:server/database.dart' as i6;

abstract base class $ServerDatabase extends i0.GeneratedDatabase {
  $ServerDatabase(super.implementation);
  i1.$UsersTable get users => i1.$UsersTable();
  i2.Posts get posts => i2.Posts();
  i3.$ActiveSessionsTable get activeSessions => i3.$ActiveSessionsTable();
  i0.TableOrViewStatements<i1.User, i1.$UsersTable> get usersQueries =>
      this.users.statements(this);
  i0.TableOrViewStatements<i2.Post, i2.Posts> get postsQueries =>
      this.posts.statements(this);
  i0.TableOrViewStatements<i3.ActiveSession, i3.$ActiveSessionsTable>
      get activeSessionsQueries => this.activeSessions.statements(this);
  @override
  Map<i0.KnownSqlDialect, Object> get dialectOptions => {
        i0.KnownSqlDialect.postgres: const i4.PostgresDialectOptions(
          useJsonb: true,
        ),
      };
  i5.SharedDrift get sharedDrift => i5.SharedDrift(this);
  @override
  i0.DatabaseSchema get schema => _$schema;
  static final i0.DatabaseSchema _$schema = i0.DatabaseSchema([
    i1.$UsersTable(),
    i2.Posts(),
    i3.$ActiveSessionsTable(),
  ]);
}

class $ActiveSessionsTable extends i6.ActiveSessions
    with i0.ResultSet<i3.ActiveSession, $ActiveSessionsTable>
    implements i0.GeneratedTable<i3.ActiveSession, $ActiveSessionsTable> {
  @override
  final String? alias;
  $ActiveSessionsTable([this.alias]);
  @override
  late final i0.TableColumn<int> user = i0.TableColumn<int>(
      name: 'user',
      sqlType: i0.SqlType.int,
      requiredDuringInsert: true,
      constraints: () => [
            const i0.ColumnNotNullConstraint(),
            const i0.ColumnForeignKeyConstraint(
              otherTableName: 'users',
              otherColumnName: 'id',
            )
          ])
    ..owningResultSet = this;
  @override
  late final i0.TableColumn<String> bearerToken = i0.TableColumn<String>(
      name: 'bearer_token',
      sqlType: i0.SqlType.text,
      requiredDuringInsert: true,
      constraints: () => [const i0.ColumnNotNullConstraint()])
    ..owningResultSet = this;
  @override
  List<i0.TableColumn> get columns => [user, bearerToken];
  @override
  String get entityName => $name;
  static const String $name = 'active_sessions';
  @override
  $ActiveSessionsTable asSelfType() => this;

  @override
  i3.ActiveSession? Function(i0.RawRow) createMapperFromPositions(
      i0.DriftDialect dialect, List<i0.ColumnPosition> positions) {
    final pos$user = positions[0].index;
    final type$0 = i0.SqlType.int.resolveIn(dialect);
    final pos$bearerToken = positions[1].index;
    final type$1 = i0.SqlType.text.resolveIn(dialect);
    return (i0.RawRow row) {
      // Not part of row if non-nullable column "user" is missing
      if (row[pos$user] == null) {
        return null;
      }
      return i3.ActiveSession(
        user: type$0.dartValue(row[pos$user]!),
        bearerToken: type$1.dartValue(row[pos$bearerToken]!),
      );
    };
  }

  @override
  $ActiveSessionsTable withAlias(String alias) {
    return $ActiveSessionsTable(alias);
  }
}

class ActiveSession extends i0.LegacyDataClass
    implements i0.Insertable<i3.ActiveSession> {
  final int user;
  final String bearerToken;
  const ActiveSession({required this.user, required this.bearerToken});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['user'] = i0.Variable<int>(user, i0.SqlType.int);
    map['bearer_token'] = i0.Variable<String>(bearerToken, i0.SqlType.text);
    return map;
  }

  i3.ActiveSessionsCompanion toCompanion(bool nullToAbsent) {
    return i3.ActiveSessionsCompanion(
      user: i0.Value(user),
      bearerToken: i0.Value(bearerToken),
    );
  }

  factory ActiveSession.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return ActiveSession(
      user: serializer.fromJson<int>(json['user']),
      bearerToken: serializer.fromJson<String>(json['bearerToken']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'user': serializer.toJson<int>(user),
      'bearerToken': serializer.toJson<String>(bearerToken),
    };
  }

  i3.ActiveSession copyWith({int? user, String? bearerToken}) =>
      i3.ActiveSession(
        user: user ?? this.user,
        bearerToken: bearerToken ?? this.bearerToken,
      );
  ActiveSession copyWithCompanion(i3.ActiveSessionsCompanion data) {
    return ActiveSession(
      user: data.user.present ? data.user.value : this.user,
      bearerToken:
          data.bearerToken.present ? data.bearerToken.value : this.bearerToken,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActiveSession(')
          ..write('user: $user, ')
          ..write('bearerToken: $bearerToken')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(user, bearerToken);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i3.ActiveSession &&
          other.user == this.user &&
          other.bearerToken == this.bearerToken);
}

class ActiveSessionsCompanion extends i0.UpdateCompanion<i3.ActiveSession> {
  final i0.Value<int> user;
  final i0.Value<String> bearerToken;
  final i0.Value<int> rowid;
  const ActiveSessionsCompanion({
    this.user = const i0.Value.absent(),
    this.bearerToken = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  ActiveSessionsCompanion.insert({
    required int user,
    required String bearerToken,
    this.rowid = const i0.Value.absent(),
  })  : user = i0.Value(user),
        bearerToken = i0.Value(bearerToken);
  static i0.Insertable<i3.ActiveSession> custom({
    i0.Expression<int>? user,
    i0.Expression<String>? bearerToken,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (user != null) 'user': user,
      if (bearerToken != null) 'bearer_token': bearerToken,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i3.ActiveSessionsCompanion copyWith(
      {i0.Value<int>? user,
      i0.Value<String>? bearerToken,
      i0.Value<int>? rowid}) {
    return i3.ActiveSessionsCompanion(
      user: user ?? this.user,
      bearerToken: bearerToken ?? this.bearerToken,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (user.present) {
      map['user'] = i0.Variable<int>(user.value, i0.SqlType.int);
    }
    if (bearerToken.present) {
      map['bearer_token'] =
          i0.Variable<String>(bearerToken.value, i0.SqlType.text);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value, i0.SqlType.int);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActiveSessionsCompanion(')
          ..write('user: $user, ')
          ..write('bearerToken: $bearerToken, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}
