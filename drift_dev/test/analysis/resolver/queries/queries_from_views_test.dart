import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  test('select from view', () async {
    final backend = await TestBackend.inTest({
      'foo|lib/a.drift': '''
CREATE TABLE artists (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name VARCHAR NOT NULL
);

CREATE TABLE albums (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  artist INTEGER NOT NULL REFERENCES artists (id)
);

CREATE TABLE tracks (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  album INTEGER NOT NULL REFERENCES albums (id),
  duration_seconds INTEGER NOT NULL,
  was_single BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE VIEW total_duration_by_artist_view AS
  SELECT a.*, SUM(tracks.duration_seconds) AS duration
  FROM artists a
    INNER JOIN albums ON albums.artist = a.id
    INNER JOIN tracks ON tracks.album = albums.id
  GROUP BY a.id;

totalDurationByArtist:
SELECT * FROM total_duration_by_artist_view;
''',
    });

    final file =
        await backend.driver.fullyAnalyze(Uri.parse('package:foo/a.drift'));

    expect(file.allErrors, isEmpty);

    final results = file.fileAnalysis!;
    final query = results.resolvedQueries.values
        .singleWhere((q) => q.name == 'totalDurationByArtist');

    expect(
      query,
      returnsColumns({
        'id': DriftSqlType.int,
        'name': DriftSqlType.string,
        'duration': DriftSqlType.int,
      }),
    );
  });
}
