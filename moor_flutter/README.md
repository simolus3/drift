# Moor
Moor is a reactive persistence library for Flutter and Dart, built on top of
sqlite. 
Moor is

- __Flexible__: Moor let's you write queries in both SQL and Dart, 
providing fluent apis for both languages. You can filter and order results 
or use joins to run queries on multiple tables. You can even use complex 
sql features like `WITH` and `WINDOW` clauses.
- __🔥 Feature rich__: Moor has builtin support for transactions, schema 
migrations, complex filters and expressions, batched updates and joins. We 
even have a builtin IDE for SQL!
- __📦 Modular__: Thanks to builtin support for daos and `import`s in sql files, moor helps you keep your database code simple.
- __🛡️ Safe__: Moor generates typesafe code based on your tables and queries. If you make a mistake in your queries, moor will find it at compile time and
provide helpful and descriptive lints.
- __Reactive__: Turn any sql query into an auto-updating stream! This includes complex queries across many tables
- __⚙️ Cross-Platform support__: Moor works on Android, iOS, macOS, Windows, Linux and the web. [This template](https://github.com/rodydavis/moor_shared) is a Flutter todo app that works on all platforms
- __🗡️ Battle tested and production ready__: Moor is stable and well tested with a wide range of unit and integration tests. It powers production Flutter apps.

With moor, persistence on Flutter is fun!

__To start using moor, read our detailed [docs](https://drift.simonbinder.eu/docs/getting-started/).__

If you have any questions, feedback or ideas, feel free to [create an
issue](https://github.com/simolus3/drift/issues/new). If you enjoy this
project, I'd appreciate your [🌟 on GitHub](https://github.com/simolus3/drift/).

## For the web
For information to use this library on the web (including Flutter web), follow the 
instructions [here](https://drift.simonbinder.eu/web). Keep in mind that web support is still experimental.
