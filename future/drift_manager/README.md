This is an optional extension package for drift making it easier to build common queries
and joins with the [manager interface](https://drift.simonbinder.eu/dart_api/manager/).

## Installation

For a full setup guide, see the [full documentation](https://drift.simonbinder.eu/dart_api/manager/).

If you already have an existing drift database, use `dart pub add drift_manager` to add this package.
Additionally, configure `drift_dev` to generate manager code:

```yaml
# build.yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          generate_manager: true
          # Additional drift options...
```

## Usage

Methods in this package are not typically used directly. Instead, `drift_dev` uses them to generate
code making some drift queries easier to use.
For a full overview, see the [documentation](https://drift.simonbinder.eu/dart_api/manager/).

```dart
// Queries
await managers.todoItems.filter((f) => f.id(1)).getSingle();

// Easily referencing foreign keys
final todosWithRefs = await managers.todoItems.withReferences().get();
for (final (todo, refs) in todosWithRefs) {
  final category = await refs.category?.getSingle();
}
```
