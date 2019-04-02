---
layout: feature
title: Custom queries
parent: Writing queries
---

# Custom statements
Altough moor includes a fluent api that can be used to model most statements, advanced
features like `GROUP BY` statements or window functions are not yet supported. You can
use these features with custom statements. You don't have to miss out on other benefits
moor brings, though: Parsing the rows and query-streams also work on custom statements.

## Custom select statements
You can issue custom queries by calling `customSelect` for a one-time query or
`customSelectStream` for a query stream that automatically emits a new set of items when
the underlying data changes. Using the todo example introduced in the 
[getting started guide]({{site.common_links.getting_started | absolute_url}}), we can
write this query which will load the amount of todo entries in each category:
```dart
class CategoryWithCount {
  final Category category;
  final int count; // amount of entries in this category

  CategoryWithCount(this.category, this.count);
}

// then, in the database class:
Stream<List<CategoryWithCount>> categoriesWithCount() {
    // select all categories and load how many associated entries there are for
    // each category
    return customSelectStream(
      'SELECT *, (SELECT COUNT(*) FROM todos WHERE category = c.id) AS "amount" FROM categories c;',
      readsFrom: {todos, categories}, // used for the stream: the stream will update when either table changes
      ).map((rows) {
        // we get list of rows here. We just have to turn the raw data from the row into a
        // CategoryWithCount. As we defined the Category table earlier, moor knows how to parse
        // a category. The only thing left to do manually is extracting the amount
        return rows
          .map((row) => CategoryWithCount(Category.fromData(row.data, this), row.readInt('amount')))
          .toList();
    });
  }
```
For custom selects, you should use the `readsFrom` parameter to specify from which tables the query is
reading. When using a `Stream`, moor will be able to know after which updates the stream should emit
items. 

## Custom update statements
For update and delete statements, you can use `customUpdate`. Just like `customSelect`, that method
also takes a sql statement and optional variables. You can also tell moor which tables will be
affected by your query using the optional `updates` parameter. That will help with other select
streams, which will then update automatically.
