import 'package:drift/drift.dart';
import 'package:drift_dev/src/analysis/options.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  test('experimental inference - integration test', () async {
    final state = await TestBackend.inTest({
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

totalDurationByArtist:
  SELECT a.*, SUM(tracks.duration_seconds) AS duration
  FROM artists a
    INNER JOIN albums ON albums.artist = a.id
    INNER JOIN tracks ON tracks.album = albums.id
  GROUP BY a.id;
    '''
    }, options: const DriftOptions.defaults());

    final file = await state.analyze('package:foo/a.drift');
    state.expectNoErrors();

    final totalDurationByArtist =
        file.fileAnalysis!.resolvedQueries[file.id('totalDurationByArtist')];

    expect(
      totalDurationByArtist,
      returnsColumns({
        'id': DriftSqlType.int,
        'name': DriftSqlType.string,
        'duration': DriftSqlType.int,
      }),
    );
  });
}
