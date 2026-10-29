import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  test('infers types for bm25 and snippet functions', () async {
    final backend = await TestBackend.inTest({
      'a|lib/a.drift': '''
CREATE VIRTUAL TABLE songs_fts USING fts5(uuid, source_bank_id, title, lyrics, composer, poet, translator, pitch_field);

song_fulltext_search(:match_string AS TEXT):
  SELECT
      BM25(songs_fts, 0.0, 0.0, 10.0, 0.5, 5.0, 5.0, 2.0, 0.0) AS rank
      ,uuid
      ,source_bank_id
      ,pitch_field
      ,SNIPPET(songs_fts, 2, '<?', '?>', '...', 30) AS match_title
      ,SNIPPET(songs_fts, 3, '<?', '?>', '...', 30) AS match_lyrics
      ,SNIPPET(songs_fts, 4, '<?', '?>', '...', 30) AS match_composer
      ,SNIPPET(songs_fts, 5, '<?', '?>', '...', 30) AS match_poet
      ,SNIPPET(songs_fts, 6, '<?', '?>', '...', 30) AS match_translator
    FROM songs_fts
    WHERE songs_fts MATCH :match_string
    ORDER BY rank;
''',
    }, options: DriftOptions.defaults(modules: [SqlModule.fts5]));

    final file = await backend.analyze('package:a/a.drift');
    backend.expectNoErrors();

    final query =
        file.fileAnalysis!.resolvedQueries.values.single as SqlSelectQuery;
    expect(
      query.resultSet.columns.map(
        (e) => (
          e.dartGetterName(const []),
          (e as ScalarResultColumn).sqlType.builtin,
        ),
      ),
      [
        ('rank', BuiltinType.double),
        ('uuid', BuiltinType.string),
        ('sourceBankId', BuiltinType.string),
        ('pitchField', BuiltinType.string),
        ('matchTitle', BuiltinType.string),
        ('matchLyrics', BuiltinType.string),
        ('matchComposer', BuiltinType.string),
        ('matchPoet', BuiltinType.string),
        ('matchTranslator', BuiltinType.string),
      ],
    );
  });
}
