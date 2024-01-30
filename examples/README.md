## Examples using drift

This collection of examples demonstrates how to use some advanced drift features.

- `app`: A cross-platform Flutter app built with recommended drift options.
- `encryption`: A very simple Flutter app running an encrypted drift database.
- `migrations_example`: Example showing to how to generate test utilities to verify schema migration.
- `modular`: Example using drift's upcoming modular generation mode.
- `with_built_value`: Configure `build_runner` so that drift-generated classes can be used by `build_runner`.
- `multi_package`: This example shows how to share drift definitions between packages.

These two examples exist to highlight a feature of `package:drift/web.dart` and `package:drift/web/workers.dart`.
However, the setup shown here is now a core drift feature thanks to `WasmDatabase.open`, which means that this
is no longer needed:

- `flutter_web_worker_example`: Asynchronously run a drift database through a web worker with Flutter.
- `web_worker_example`: Asynchronously run a drift database through a web worker, without Flutter.
