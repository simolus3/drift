// #docregion email-queries
import 'package:drift/drift.dart';
import 'package:drift/extensions/fts5.dart';

// #enddocregion email-queries

import 'example.drift.dart';
import 'fts5.drift.dart';

class DartExample extends ExampleDrift {
  DartExample(super.attachedDatabase);

  // #docregion watchInCategory
  Stream<List<Todo>> watchInCategory(int category) {
    return filterTodos((todos) => todos.category.equals(category)).watch();
  }

  // #enddocregion watchInCategory

  Email get email => throw 'stub for snippet';

  // #docregion email-queries
  // find emails matching the fts5 query, best matches first.
  Future<List<EmailData>> searchEmails(String query) {
    return (select(email)
          ..where((tbl) => tbl.match(query))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.rank)]))
        .get();
  }

  // return the titles of all matching emails with the search terms
  // wrapped in `<b>` tags.
  Future<List<String>> highlightedTitles(String query) {
    final highlight = email.highlight(
      email.title,
      before: '<b>',
      after: '</b>',
    );

    return (selectOnly(email)
          ..addColumns([highlight])
          ..where(email.match(query)))
        .map((row) => row.read(highlight)!)
        .get();
  }
  // #enddocregion email-queries
}
