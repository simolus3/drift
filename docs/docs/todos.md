drift_sqflite not working with BigInt
Use BigInt in expressions
add datetime storage migration docs
indexes
references


In JsonKey docs

    To use the SQL column name as the JSON key during serialization too, set `use_sql_column_name_as_json_key` to `true` in your `build.yaml`.

    ??? example "`build.yaml`"

        ```yaml
        targets:
          $default:
            builders:
              drift_dev:
                options:
                  use_sql_column_name_as_json_key : true
        ```