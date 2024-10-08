
### Data Class Name

Drift generates a data class for each table:

- Table name ending with "s": Remove the "s" (e.g., `Superheroes` → `Superhero`)
- Other table names: Append "Data" (e.g., `Category` → `CategoryData`)

=== "Dart"

    This name can be customized by using the `@DataClassName` decorator.

    {{ load_snippet('bad_name','lib/snippets/schema.dart.excerpt.json') }}

=== "SQL"

    The data class name can be customized by using the `AS` keyword in the `CREATE TABLE` statement.

    {{ load_snippet('sql_custom_dataclass_name','lib/snippets/drift_files/tables.drift.excerpt.json', indent=4, title="tables.drift") }}

### Json Key

Drift automatically generates `fromJson` and `toJson` methods for each table's data class. These methods handle JSON serialization and deserialization. By default, the JSON keys correspond to the column names, converted to `snake_case`. For example:

- A column named `emailAddress` will use `email_address` as its JSON key.
- A column named `userName` will use `user_name` as its JSON key.

=== "Dart"
    This name can be customized by using the `@JsonKey` decorator.

    {{ load_snippet('json_key','lib/snippets/schema.dart.excerpt.json') }}

=== "SQL"
    The JSON key can be customized by using `JSON KEY` in the `CREATE TABLE` statement.

    {{ load_snippet('sql_json_key','lib/snippets/drift_files/tables.drift.excerpt.json', indent=4, title="tables.drift") }}

#### Json Key from Column Name

Drift offers an option to use the column name as the JSON key. When this option is enabled, the column name specified in  `named()` method in Dart will be used directly as the JSON key.

Enable this by setting `use_column_name_as_json_key` in your `build.yaml` file:

```yaml title="build.yaml"
targets:
  $default:
    builders:
      drift_dev:
        options:
          use_sql_column_name_as_json_key: false # (default)
          # To use column name as JSON key
          # use_sql_column_name_as_json_key: true 
```
