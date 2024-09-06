---

title: "DevTools extension"
description: Inspect drift databases within DevTools

---

[DevTools](https://docs.flutter.dev/tools/devtools) is a collection of performance and debugging
tools for Dart and Flutter apps maintained by the Flutter team.
When using drift, you can inspect the contents of your drift databases directly
within DevTools! Drift provides tools to inspect your database and to diagnose
potential problems, helping you fix common issues and debug unexpected query results.

## Setup

DevTools is attached to running Dart and Flutter apps. Depending on how you start your app,
there are different ways to open a DevTools instance:

1. When using `flutter run`, a line printing "The Flutter DevTools debugger and profiler is available at"
   shows the link to your DevTools instance.
2. For `dart run`, you need to pass the `--observe` flag to get the DevTools link.
3. [VSCode](https://docs.flutter.dev/tools/devtools/vscode) and [IntelliJ and Android Studio](https://docs.flutter.dev/tools/devtools/android-studio)
   also have ways to open DevTools after starting your app.

Drift contributes a DevTools extension that is available to all apps depending on `drift`.
The first time you're using the extension, you may have to enable it explicitly. For that,
click on the extensions icon at the top of the DevTools window:

![Screenshot of an DevTools window, with the extensions button in the window bar highlighted](setup_0.png)

In the dialog that opens, make sure that `package:drift` is enabled:

![Dialog showing the drift extension, with a button marking it as enabled](setup_1.png)

## Usage

After enabling the extension, select the drift tab in DevTools:

![Screenshot of the drift DevTools extension, listing opened databases and tables](setup_2.png)

In the extension, the top pane lists all drift databases currently open and where their class
has been defined.
After selecting a database from that list, you can inspect its tables and modify their content.
The extension uses the [drift_db_viewer](https://pub.dev/packages/drift_db_viewer) package written
by [Koen Van Looveren](https://github.com/vanlooverenkoen) for this, but you don't have to add
a dependency on that package as it only runs within the DevTools context.

### Schema validation

Especially when testing migrations, it can happen that the expected schema (that drift would create
with `CREATE TABLE` statements when opening a new database) does not exactly match the schema
of your current database.
Depending on the mismatch, this can cause hard to detect errors when selecting from queries
or modifying rows.
In the DevTools extension, you can use "Validate schema" to make drift compare the expected and
the actual schema, quickly warning about potential issues.
