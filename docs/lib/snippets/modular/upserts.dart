import 'package:drift/drift.dart';
import 'package:drift/internal/modular.dart';

import 'upserts.drift.dart';

// #docregion words-table
class Words extends Table {
  TextColumn get word => text()();
  IntColumn get usages => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {word};
}
// #enddocregion words-table

// #docregion upsert-target
class MatchResults extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get teamA => text()();
  TextColumn get teamB => text()();
  BoolColumn get teamAWon => boolean()();

  @override
  List<Set<Column<Object>>>? get uniqueKeys => [
        {teamA, teamB}
      ];
}
// #enddocregion upsert-target

extension DocumentationSnippets on ModularAccessor {
  $WordsTable get words => throw 'stub';
  $MatchResultsTable get matches => throw 'stub';

  // #docregion track-word
  Future<void> trackWord(String word) {
    return into(words).insert(
      WordsCompanion.insert(word: word),
      onConflict: DoUpdate(
          (old) => WordsCompanion.custom(usages: old.usages + Constant(1))),
    );
  }
  // #enddocregion track-word

  // #docregion upsert-target
  Future<void> insertMatch(String teamA, String teamB, bool teamAWon) {
    final data = MatchResultsCompanion.insert(
        teamA: teamA, teamB: teamB, teamAWon: teamAWon);

    return into(matches).insert(data,
        onConflict:
            DoUpdate((old) => data, target: [matches.teamA, matches.teamB]));
  }
  // #enddocregion upsert-target
}
