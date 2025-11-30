import 'dart:async';

import 'package:drift_website/src/search/database.dart';
import 'package:drift_website/src/search/loader.dart';
import 'package:sqlite3/sqlite3.dart';

/// Testing the `SearchDatabase` by running a search. To test this,
///
///  1. Run `dart run tool/build_search_index.dart`.
///  2. Serve web (e.g. with `dhttpd --port 8080`).
///  3. Run say `dart run tool/test_search.dart testing`
void main(List<String> args) async {
  final db = await SearchDatabase.open(
    sqlite3,
    SearchIndexLoader.http(Uri.parse('http://localhost:8080/search.db.json')),
  );
  final term = args.join(' ');

  await for (final result
      in db.search(term, cancel: Completer().future).take(5)) {
    print('${result.title}: ${result.highlight}');
  }

  db.close();
}
