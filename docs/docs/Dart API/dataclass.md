To update the name of a column when serializing data to json, annotate the getter with
[`@JsonKey`](https://pub.dev/documentation/drift/latest/drift/JsonKey-class.html).

You can change the name of the generated data class too. By default, drift will stip a trailing
`s` from the table name (so a `Users` table would have a `User` data class).
That doesn't work in all cases though. With the `EnabledCategories` class from above, we'd get
a `EnabledCategorie` data class. In those cases, you can use the [`@DataClassName`](https://pub.dev/documentation/drift/latest/drift/DataClassName-class.html)
annotation to set the desired name.

## Existing row classes

By default, drift generates a row class for each table. This row class can be used to access all columns, it also
implements `hashCode`, `operator==` and a few other useful operators.
When you want to use your own type hierarchy, or have more control over the generated classes, you can
also tell drift to your own class or type:

{{ load_snippet('custom-type','lib/snippets/dart_api/tables.dart.excerpt.json') }}

Drift verifies that the type is suitable for storing a row of that table.
More details about this feature are [described here](../custom_row_classes.md).

