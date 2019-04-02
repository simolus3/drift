---
layout: post
title: Custom queries
parent: Writing queries
---

# Custom statements
You can also issue custom queries by calling `customUpdate` for update and deletes and
`customSelect` or `customSelectStream` for select statements. Using the todo example
above, here is a simple custom query that loads all categories and how many items are
in each category:
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
        readsFrom: {todos, categories}).map((rows) {
      // when we have the result set, map each row to the data class
      return rows
          .map((row) => CategoryWithCount(Category.fromData(row.data, this), row.readInt('amount')))
          .toList();
    });
  }
```
For custom selects, you should use the `readsFrom` parameter to specify from which tables the query is
reading. When using a `Stream`, moor will be able to know after which updates the stream should emit
items. If you're using a custom query for updates or deletes with `customUpdate`, you should also
use the `updates` parameter to let moor know which tables you're touching.
