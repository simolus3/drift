// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:drift_docs/snippets/modular/upserts.drift.dart' as i1;
import 'package:drift_docs/snippets/modular/upserts.dart' as i2;
import 'package:drift/src/runtime/query_builder/query_builder.dart' as i3;

class $WordsTable extends i2.Words with i0.TableInfo<$WordsTable, i1.Word> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordsTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _wordMeta =
      const i0.VerificationMeta('word');
  @override
  late final i0.GeneratedColumn<String> word = i0.GeneratedColumn<String>(
      'word', aliasedName, false,
      type: i0.DriftSqlType.string, requiredDuringInsert: true);
  static const i0.VerificationMeta _usagesMeta =
      const i0.VerificationMeta('usages');
  @override
  late final i0.GeneratedColumn<int> usages = i0.GeneratedColumn<int>(
      'usages', aliasedName, false,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const i3.Constant(1));
  @override
  List<i0.GeneratedColumn> get $columns => [word, usages];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'words';
  @override
  i0.VerificationContext validateIntegrity(i0.Insertable<i1.Word> instance,
      {bool isInserting = false}) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word')) {
      context.handle(
          _wordMeta, word.isAcceptableOrUnknown(data['word']!, _wordMeta));
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('usages')) {
      context.handle(_usagesMeta,
          usages.isAcceptableOrUnknown(data['usages']!, _usagesMeta));
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {word};
  @override
  i1.Word map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.Word(
      word: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}word'])!,
      usages: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}usages'])!,
    );
  }

  @override
  $WordsTable createAlias(String alias) {
    return $WordsTable(attachedDatabase, alias);
  }
}

class Word extends i0.DataClass implements i0.Insertable<i1.Word> {
  final String word;
  final int usages;
  const Word({required this.word, required this.usages});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['word'] = i0.Variable<String>(word);
    map['usages'] = i0.Variable<int>(usages);
    return map;
  }

  i1.WordsCompanion toCompanion(bool nullToAbsent) {
    return i1.WordsCompanion(
      word: i0.Value(word),
      usages: i0.Value(usages),
    );
  }

  factory Word.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return Word(
      word: serializer.fromJson<String>(json['word']),
      usages: serializer.fromJson<int>(json['usages']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'word': serializer.toJson<String>(word),
      'usages': serializer.toJson<int>(usages),
    };
  }

  i1.Word copyWith({String? word, int? usages}) => i1.Word(
        word: word ?? this.word,
        usages: usages ?? this.usages,
      );
  Word copyWithCompanion(i1.WordsCompanion data) {
    return Word(
      word: data.word.present ? data.word.value : this.word,
      usages: data.usages.present ? data.usages.value : this.usages,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Word(')
          ..write('word: $word, ')
          ..write('usages: $usages')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(word, usages);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.Word &&
          other.word == this.word &&
          other.usages == this.usages);
}

class WordsCompanion extends i0.UpdateCompanion<i1.Word> {
  final i0.Value<String> word;
  final i0.Value<int> usages;
  final i0.Value<int> rowid;
  const WordsCompanion({
    this.word = const i0.Value.absent(),
    this.usages = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  WordsCompanion.insert({
    required String word,
    this.usages = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  }) : word = i0.Value(word);
  static i0.Insertable<i1.Word> custom({
    i0.Expression<String>? word,
    i0.Expression<int>? usages,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (word != null) 'word': word,
      if (usages != null) 'usages': usages,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.WordsCompanion copyWith(
      {i0.Value<String>? word, i0.Value<int>? usages, i0.Value<int>? rowid}) {
    return i1.WordsCompanion(
      word: word ?? this.word,
      usages: usages ?? this.usages,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (word.present) {
      map['word'] = i0.Variable<String>(word.value);
    }
    if (usages.present) {
      map['usages'] = i0.Variable<int>(usages.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordsCompanion(')
          ..write('word: $word, ')
          ..write('usages: $usages, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

typedef $$WordsTableCreateCompanionBuilder = i1.WordsCompanion Function({
  required String word,
  i0.Value<int> usages,
  i0.Value<int> rowid,
});
typedef $$WordsTableUpdateCompanionBuilder = i1.WordsCompanion Function({
  i0.Value<String> word,
  i0.Value<int> usages,
  i0.Value<int> rowid,
});

class $$WordsTableTableManager extends i0.RootTableManager<
    i0.GeneratedDatabase,
    i1.$WordsTable,
    i1.Word,
    i1.$$WordsTableFilterComposer,
    i1.$$WordsTableOrderingComposer,
    $$WordsTableCreateCompanionBuilder,
    $$WordsTableUpdateCompanionBuilder,
    (i1.Word, $$WordsTableWithReferences),
    i1.Word> {
  $$WordsTableTableManager(i0.GeneratedDatabase db, i1.$WordsTable table)
      : super(i0.TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              i1.$$WordsTableFilterComposer(i0.ComposerState(db, table)),
          orderingComposer:
              i1.$$WordsTableOrderingComposer(i0.ComposerState(db, table)),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e, $$WordsTableWithReferences(db, e))).toList(),
          updateCompanionCallback: ({
            i0.Value<String> word = const i0.Value.absent(),
            i0.Value<int> usages = const i0.Value.absent(),
            i0.Value<int> rowid = const i0.Value.absent(),
          }) =>
              i1.WordsCompanion(
            word: word,
            usages: usages,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String word,
            i0.Value<int> usages = const i0.Value.absent(),
            i0.Value<int> rowid = const i0.Value.absent(),
          }) =>
              i1.WordsCompanion.insert(
            word: word,
            usages: usages,
            rowid: rowid,
          ),
        ));
}

typedef $$WordsTableProcessedTableManager = i0.ProcessedTableManager<
    i0.GeneratedDatabase,
    i1.$WordsTable,
    i1.Word,
    i1.$$WordsTableFilterComposer,
    i1.$$WordsTableOrderingComposer,
    $$WordsTableCreateCompanionBuilder,
    $$WordsTableUpdateCompanionBuilder,
    (i1.Word, $$WordsTableWithReferences),
    i1.Word>;

class $$WordsTableFilterComposer
    extends i0.FilterComposer<i0.GeneratedDatabase, i1.$WordsTable> {
  $$WordsTableFilterComposer(super.$state);
  i0.ColumnFilters<String> get word => $state.composableBuilder(
      column: $state.table.word,
      builder: (column, joinBuilders) =>
          i0.ColumnFilters(column, joinBuilders: joinBuilders));

  i0.ColumnFilters<int> get usages => $state.composableBuilder(
      column: $state.table.usages,
      builder: (column, joinBuilders) =>
          i0.ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$WordsTableOrderingComposer
    extends i0.OrderingComposer<i0.GeneratedDatabase, i1.$WordsTable> {
  $$WordsTableOrderingComposer(super.$state);
  i0.ColumnOrderings<String> get word => $state.composableBuilder(
      column: $state.table.word,
      builder: (column, joinBuilders) =>
          i0.ColumnOrderings(column, joinBuilders: joinBuilders));

  i0.ColumnOrderings<int> get usages => $state.composableBuilder(
      column: $state.table.usages,
      builder: (column, joinBuilders) =>
          i0.ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$WordsTableWithReferences {
  // ignore: unused_field
  final i0.GeneratedDatabase _db;
  final i1.Word _item;
  $$WordsTableWithReferences(this._db, this._item);
}

class $MatchResultsTable extends i2.MatchResults
    with i0.TableInfo<$MatchResultsTable, i1.MatchResult> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MatchResultsTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  @override
  late final i0.GeneratedColumn<int> id = i0.GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          i0.GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const i0.VerificationMeta _teamAMeta =
      const i0.VerificationMeta('teamA');
  @override
  late final i0.GeneratedColumn<String> teamA = i0.GeneratedColumn<String>(
      'team_a', aliasedName, false,
      type: i0.DriftSqlType.string, requiredDuringInsert: true);
  static const i0.VerificationMeta _teamBMeta =
      const i0.VerificationMeta('teamB');
  @override
  late final i0.GeneratedColumn<String> teamB = i0.GeneratedColumn<String>(
      'team_b', aliasedName, false,
      type: i0.DriftSqlType.string, requiredDuringInsert: true);
  static const i0.VerificationMeta _teamAWonMeta =
      const i0.VerificationMeta('teamAWon');
  @override
  late final i0.GeneratedColumn<bool> teamAWon = i0.GeneratedColumn<bool>(
      'team_a_won', aliasedName, false,
      type: i0.DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
          'CHECK ("team_a_won" IN (0, 1))'));
  @override
  List<i0.GeneratedColumn> get $columns => [id, teamA, teamB, teamAWon];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'match_results';
  @override
  i0.VerificationContext validateIntegrity(
      i0.Insertable<i1.MatchResult> instance,
      {bool isInserting = false}) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('team_a')) {
      context.handle(
          _teamAMeta, teamA.isAcceptableOrUnknown(data['team_a']!, _teamAMeta));
    } else if (isInserting) {
      context.missing(_teamAMeta);
    }
    if (data.containsKey('team_b')) {
      context.handle(
          _teamBMeta, teamB.isAcceptableOrUnknown(data['team_b']!, _teamBMeta));
    } else if (isInserting) {
      context.missing(_teamBMeta);
    }
    if (data.containsKey('team_a_won')) {
      context.handle(_teamAWonMeta,
          teamAWon.isAcceptableOrUnknown(data['team_a_won']!, _teamAWonMeta));
    } else if (isInserting) {
      context.missing(_teamAWonMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<i0.GeneratedColumn>> get uniqueKeys => [
        {teamA, teamB},
      ];
  @override
  i1.MatchResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.MatchResult(
      id: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}id'])!,
      teamA: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}team_a'])!,
      teamB: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}team_b'])!,
      teamAWon: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.bool, data['${effectivePrefix}team_a_won'])!,
    );
  }

  @override
  $MatchResultsTable createAlias(String alias) {
    return $MatchResultsTable(attachedDatabase, alias);
  }
}

class MatchResult extends i0.DataClass
    implements i0.Insertable<i1.MatchResult> {
  final int id;
  final String teamA;
  final String teamB;
  final bool teamAWon;
  const MatchResult(
      {required this.id,
      required this.teamA,
      required this.teamB,
      required this.teamAWon});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['team_a'] = i0.Variable<String>(teamA);
    map['team_b'] = i0.Variable<String>(teamB);
    map['team_a_won'] = i0.Variable<bool>(teamAWon);
    return map;
  }

  i1.MatchResultsCompanion toCompanion(bool nullToAbsent) {
    return i1.MatchResultsCompanion(
      id: i0.Value(id),
      teamA: i0.Value(teamA),
      teamB: i0.Value(teamB),
      teamAWon: i0.Value(teamAWon),
    );
  }

  factory MatchResult.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return MatchResult(
      id: serializer.fromJson<int>(json['id']),
      teamA: serializer.fromJson<String>(json['teamA']),
      teamB: serializer.fromJson<String>(json['teamB']),
      teamAWon: serializer.fromJson<bool>(json['teamAWon']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'teamA': serializer.toJson<String>(teamA),
      'teamB': serializer.toJson<String>(teamB),
      'teamAWon': serializer.toJson<bool>(teamAWon),
    };
  }

  i1.MatchResult copyWith(
          {int? id, String? teamA, String? teamB, bool? teamAWon}) =>
      i1.MatchResult(
        id: id ?? this.id,
        teamA: teamA ?? this.teamA,
        teamB: teamB ?? this.teamB,
        teamAWon: teamAWon ?? this.teamAWon,
      );
  MatchResult copyWithCompanion(i1.MatchResultsCompanion data) {
    return MatchResult(
      id: data.id.present ? data.id.value : this.id,
      teamA: data.teamA.present ? data.teamA.value : this.teamA,
      teamB: data.teamB.present ? data.teamB.value : this.teamB,
      teamAWon: data.teamAWon.present ? data.teamAWon.value : this.teamAWon,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MatchResult(')
          ..write('id: $id, ')
          ..write('teamA: $teamA, ')
          ..write('teamB: $teamB, ')
          ..write('teamAWon: $teamAWon')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, teamA, teamB, teamAWon);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.MatchResult &&
          other.id == this.id &&
          other.teamA == this.teamA &&
          other.teamB == this.teamB &&
          other.teamAWon == this.teamAWon);
}

class MatchResultsCompanion extends i0.UpdateCompanion<i1.MatchResult> {
  final i0.Value<int> id;
  final i0.Value<String> teamA;
  final i0.Value<String> teamB;
  final i0.Value<bool> teamAWon;
  const MatchResultsCompanion({
    this.id = const i0.Value.absent(),
    this.teamA = const i0.Value.absent(),
    this.teamB = const i0.Value.absent(),
    this.teamAWon = const i0.Value.absent(),
  });
  MatchResultsCompanion.insert({
    this.id = const i0.Value.absent(),
    required String teamA,
    required String teamB,
    required bool teamAWon,
  })  : teamA = i0.Value(teamA),
        teamB = i0.Value(teamB),
        teamAWon = i0.Value(teamAWon);
  static i0.Insertable<i1.MatchResult> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? teamA,
    i0.Expression<String>? teamB,
    i0.Expression<bool>? teamAWon,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (teamA != null) 'team_a': teamA,
      if (teamB != null) 'team_b': teamB,
      if (teamAWon != null) 'team_a_won': teamAWon,
    });
  }

  i1.MatchResultsCompanion copyWith(
      {i0.Value<int>? id,
      i0.Value<String>? teamA,
      i0.Value<String>? teamB,
      i0.Value<bool>? teamAWon}) {
    return i1.MatchResultsCompanion(
      id: id ?? this.id,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      teamAWon: teamAWon ?? this.teamAWon,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (teamA.present) {
      map['team_a'] = i0.Variable<String>(teamA.value);
    }
    if (teamB.present) {
      map['team_b'] = i0.Variable<String>(teamB.value);
    }
    if (teamAWon.present) {
      map['team_a_won'] = i0.Variable<bool>(teamAWon.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatchResultsCompanion(')
          ..write('id: $id, ')
          ..write('teamA: $teamA, ')
          ..write('teamB: $teamB, ')
          ..write('teamAWon: $teamAWon')
          ..write(')'))
        .toString();
  }
}

typedef $$MatchResultsTableCreateCompanionBuilder = i1.MatchResultsCompanion
    Function({
  i0.Value<int> id,
  required String teamA,
  required String teamB,
  required bool teamAWon,
});
typedef $$MatchResultsTableUpdateCompanionBuilder = i1.MatchResultsCompanion
    Function({
  i0.Value<int> id,
  i0.Value<String> teamA,
  i0.Value<String> teamB,
  i0.Value<bool> teamAWon,
});

class $$MatchResultsTableTableManager extends i0.RootTableManager<
    i0.GeneratedDatabase,
    i1.$MatchResultsTable,
    i1.MatchResult,
    i1.$$MatchResultsTableFilterComposer,
    i1.$$MatchResultsTableOrderingComposer,
    $$MatchResultsTableCreateCompanionBuilder,
    $$MatchResultsTableUpdateCompanionBuilder,
    (i1.MatchResult, $$MatchResultsTableWithReferences),
    i1.MatchResult> {
  $$MatchResultsTableTableManager(
      i0.GeneratedDatabase db, i1.$MatchResultsTable table)
      : super(i0.TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              i1.$$MatchResultsTableFilterComposer(i0.ComposerState(db, table)),
          orderingComposer: i1
              .$$MatchResultsTableOrderingComposer(i0.ComposerState(db, table)),
          withReferenceMapper: (p0) => p0
              .map((e) => (e, $$MatchResultsTableWithReferences(db, e)))
              .toList(),
          updateCompanionCallback: ({
            i0.Value<int> id = const i0.Value.absent(),
            i0.Value<String> teamA = const i0.Value.absent(),
            i0.Value<String> teamB = const i0.Value.absent(),
            i0.Value<bool> teamAWon = const i0.Value.absent(),
          }) =>
              i1.MatchResultsCompanion(
            id: id,
            teamA: teamA,
            teamB: teamB,
            teamAWon: teamAWon,
          ),
          createCompanionCallback: ({
            i0.Value<int> id = const i0.Value.absent(),
            required String teamA,
            required String teamB,
            required bool teamAWon,
          }) =>
              i1.MatchResultsCompanion.insert(
            id: id,
            teamA: teamA,
            teamB: teamB,
            teamAWon: teamAWon,
          ),
        ));
}

typedef $$MatchResultsTableProcessedTableManager = i0.ProcessedTableManager<
    i0.GeneratedDatabase,
    i1.$MatchResultsTable,
    i1.MatchResult,
    i1.$$MatchResultsTableFilterComposer,
    i1.$$MatchResultsTableOrderingComposer,
    $$MatchResultsTableCreateCompanionBuilder,
    $$MatchResultsTableUpdateCompanionBuilder,
    (i1.MatchResult, $$MatchResultsTableWithReferences),
    i1.MatchResult>;

class $$MatchResultsTableFilterComposer
    extends i0.FilterComposer<i0.GeneratedDatabase, i1.$MatchResultsTable> {
  $$MatchResultsTableFilterComposer(super.$state);
  i0.ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          i0.ColumnFilters(column, joinBuilders: joinBuilders));

  i0.ColumnFilters<String> get teamA => $state.composableBuilder(
      column: $state.table.teamA,
      builder: (column, joinBuilders) =>
          i0.ColumnFilters(column, joinBuilders: joinBuilders));

  i0.ColumnFilters<String> get teamB => $state.composableBuilder(
      column: $state.table.teamB,
      builder: (column, joinBuilders) =>
          i0.ColumnFilters(column, joinBuilders: joinBuilders));

  i0.ColumnFilters<bool> get teamAWon => $state.composableBuilder(
      column: $state.table.teamAWon,
      builder: (column, joinBuilders) =>
          i0.ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$MatchResultsTableOrderingComposer
    extends i0.OrderingComposer<i0.GeneratedDatabase, i1.$MatchResultsTable> {
  $$MatchResultsTableOrderingComposer(super.$state);
  i0.ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          i0.ColumnOrderings(column, joinBuilders: joinBuilders));

  i0.ColumnOrderings<String> get teamA => $state.composableBuilder(
      column: $state.table.teamA,
      builder: (column, joinBuilders) =>
          i0.ColumnOrderings(column, joinBuilders: joinBuilders));

  i0.ColumnOrderings<String> get teamB => $state.composableBuilder(
      column: $state.table.teamB,
      builder: (column, joinBuilders) =>
          i0.ColumnOrderings(column, joinBuilders: joinBuilders));

  i0.ColumnOrderings<bool> get teamAWon => $state.composableBuilder(
      column: $state.table.teamAWon,
      builder: (column, joinBuilders) =>
          i0.ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$MatchResultsTableWithReferences {
  // ignore: unused_field
  final i0.GeneratedDatabase _db;
  final i1.MatchResult _item;
  $$MatchResultsTableWithReferences(this._db, this._item);
}
