---
title: "Frequently asked questions"

url: /faq/
---


## Using the database
If you've created a `MyDatabase` class by following the [getting started guide]({{site.url}}/getting-started/), you
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