import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('analyzes broken fts5 query', () async {
    // Regression test for https://github.com/simolus3/drift/issues/3674. The
    // broken "SELECT highlighted_text" in the FinalRankedIDs query used to get
    // resolved against itself due to a broken scope, which then causes an
    // infinite loop in drift. So if this can be analyzed in finite time we can
    // consider the bug fixed.
    final state = await TestBackend.inTest({
      'a|lib/query.drift': '''
dictionary_search_fts5_drift:

  -- Use CTEs to find, categorize, and rank all matching IDs
  WITH RankedIDs AS (
      -- Find matches in 'term' (Kanji) - Column Priority 1
      SELECT
        TB3T.id as term_bank_id,
        rank,
        TT.term as matched_text,
        highlight(term_fts, 0, '', '') AS matched_text,
        -- Categorize the match type
        CASE
            WHEN TT.term = :query THEN 1 -- 1. Exact Match
            WHEN TT.term LIKE :query || '%' THEN 2 -- 2. Prefix Match
            ELSE 3 -- 3. Infix/N-gram/Other
        END AS match_type_priority,
        1 AS match_column_priority
      FROM term_fts AS FTS
      JOIN term_bank_v3_table AS TB3T ON FTS.rowid = TB3T.term_id
      JOIN term_table AS TT ON FTS.rowid = TT.id
      WHERE term_fts MATCH :fts_query
      
      UNION ALL
      
      -- Find matches in 'reading' - Column Priority 2
      SELECT
        TB3T.id as term_bank_id,
        rank,
        RT.reading as matched_text,
        highlight(reading_fts, 0, '', '') AS highlighted_text,
        CASE
            WHEN RT.reading = :query THEN 1
            WHEN RT.reading LIKE :query || '%' THEN 2
            ELSE 3
        END AS match_type_priority,
        2 AS match_column_priority
      FROM reading_fts AS FTS
      JOIN term_bank_v3_table AS TB3T ON FTS.rowid = TB3T.reading_id
      JOIN reading_table AS RT ON FTS.rowid = RT.id
      WHERE reading_fts MATCH :fts_query
      
      UNION ALL
      
      -- Find matches in 'definition' - Column Priority 3
      SELECT
        R.term_bank_id,
        rank,
        DT.definition as matched_text,
        highlight(definition_fts, 0, '', '') AS highlighted_text,
        CASE
            WHEN DT.definition = :query THEN 1
            WHEN DT.definition LIKE :query || '%' THEN 2
            ELSE 3
        END AS match_type_priority,
        3 AS match_column_priority
      FROM definition_fts AS FTS
      JOIN term_bank_v3_x_definition_table AS R ON FTS.rowid = R.definition_id
      JOIN definition_table AS DT ON FTS.rowid = DT.id
      WHERE definition_fts MATCH :fts_query
  ),
  FinalRankedIDs AS (
      -- For each term, select the single best match based on the priority system.
      SELECT
          term_bank_id,
          rank as best_rank,
          match_type_priority,
          match_column_priority,
          highlighted_text
      FROM (
          SELECT
              *,
              ROW_NUMBER() OVER(
                PARTITION BY term_bank_id 
                ORDER BY 
                  match_type_priority,   -- First, by the quality of the match
                  match_column_priority, -- Then, by which column was matched
                  rank                   -- Finally, by FTS5's own relevance score
              ) as rn
          FROM RankedIDs
      )
      WHERE rn = 1
  )
  -- Finally, join the best-ranked IDs with the main view to get the full data
  SELECT
    R.best_rank as fts5_rank,
    highlighted_text,
    R.match_type_priority,
    R.match_column_priority,
    V.*
  FROM term_bank_v3_search_view AS V
  JOIN FinalRankedIDs AS R ON V.id = R.term_bank_id
  ORDER BY
    R.match_type_priority,   -- 1. Sort by Match Type (Exact > Prefix > Other)
    R.match_column_priority, -- 2. Sort by Match Column (Kanji > Reading > Definition)
    V.popularity DESC,       -- 4. Sort by result frequency/popularity
    R.best_rank;             -- 3. Sort by FTS5 relevance
      ''',
    });

    await state.driver.fullyAnalyze(Uri.parse('package:a/query.drift'));
  });
}
