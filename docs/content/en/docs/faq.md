---
title: "Frequently asked questions"

url: /faq/
---

## Using the database
If you've created a `MyDatabase` class by following the [getting started guide]({{<relref "Getting started/_index.md">}}), you
still need to somehow obtain an instance of it. It's recommended to only have one (singleton) instance of your database,
so you could store that instance in a global variable:

### Vanilla flutter
```dart
MyDatabase database;

void main() {
  database = MyDatabase();
  runApp(MyFlutterApp());
}
```
It would be cleaner to use `InheritedWidgets` for that, and the `provider` package helps here:

### Provider
If you're using the [provider](https://pub.dev/packages/provider) package, you can wrap your top-level widget in a
provider that manages the database instance:
```dart
void main() {
  runApp(
    Provider<MyDatabase>(
      builder: (context) => MyDatabase(),
      child: MyFlutterApp(),
      dispose: (context, db) => db.close(),
   ),
  );
}
```
Your widgets would then have access to the database using `Provider.of<MyDatabase>(context)`.

### A more complex architecture
If you're strict on keeping your business logic out of the widget layer, you probably use some dependency injection 
framework like `kiwi` or `get_it` to instantiate services and view models. Creating a singleton instance of `MyDatabase`
in your favorite dependency injection framework for flutter hence solves this problem for you.

## How does moor compare to X?
There are a variety of good persistence libraries for Dart and Flutter.

That said, here's an incomplete (and obviously biased) list of great libraries and how moor compares to them.
If you have experience with any of these (or other) libraries and want to share how they compare to moor, please
feel invited to contribute to this page.

## sqflite
Sqflite is a Flutter package that provides bindings to the sqlite api for both iOS and Android. It's well maintained
and has stable api. In fact, moor is built on top of sqflite to send queries to the database. But even though sqflite
has an api to construct some simple queries in Dart, moor goes a bit further by

* Generating typesafe mapping code for your queries
* Providing auto-updating streams for queries
* Managing `CREATE TABLE` statements and most schema migrations
* A more fluent api to compose queries

Still, for most apps that don't need these features, sqflite can be a very fitting persistence library.

### sqlcool
Sqlcool is a lightweight library around sqflite that makes writing queries and schema management easier, it also has
auto-updating streams. It can be a decent alternative to moor if you don't want/need generated code to parse the
result of your queries.

## floor
Floor also has a lot of convenience features like auto-updating queries and schema migrations. Similar to moor, you
define the structure of your database in Dart. Then, you have write queries in sql - the mapping code if generated
by floor. Moor has a [similar feature]({{< relref "Using SQL/custom_queries.md" >}}), but it can also verify that your queries are valid at compile time. Moor
additionally has an api that let's you write some queries in Dart instead of sql.

A difference between these two is that Floor let's you write your own classes and generates mapping code around that.
Moor generates most classes for you, which can make it easier to use, but makes the api less flexible in some
instances.

## firebase
Both the Realtime Database and Cloud Datastore are easy to use persistence libraries that can sync across devices while
still working offline. Both of them feature auto-updating streams and a simple query api. However, neither of them is
a relational database, so they don't support useful sql features like aggregate functions, joins, or complex filters.

Firebase is a very good option when

- your data model can be expressed as documents instead of relations
- you don't have your own backend, but still need to synchronize data
