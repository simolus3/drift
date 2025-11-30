---
title: DAOs
description: Keep your database code modular with DAOs
---

When you have a lot of queries, putting them all into one class might become
tedious. You can avoid this by extracting some queries into classes that are
available from your main database class. Consider the following code:

<Snippet href="/lib/src/snippets/setup/todos_dao.dart" name="snippet" />

If we now change the annotation on the `AppDatabase` class to `@DriftDatabase(tables: [TodoItems], daos: [TodosDao])`
and re-run the code generation, a generated getter `todosDao` can be used to access the instance of that dao.
