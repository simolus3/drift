---

title: Data Class
description: The generated data classes for each table in your database.

---

Once you've defined your tables and run code generation, drift will generate a data class for each table.
These data classes are used to represent a row in the table and are used to interact with the database.

These dataclasses have all the usual features you'd expect from a data class, like `fromJson`, `fromJsonString`, `toJson`, `copyWith`, `toString`, `hashCode`, and `operator==`.

In addition to these methods, drift also generates a `toCompanion` method which returns a companion object that can be used to insert or update a row in the table.

### Dataclass Name

{{ load_snippet('names','lib/snippets/dart_api/tables.dart.excerpt.json') }}

By default, drift will strip a trailing `s` from the table name (e.g. The `Users` table would have a `User` data class).   

That doesn't work well in all cases. For instance `EnabledCategories` class from above, we'd get
a `EnabledCategorie` data class. In those cases, you can use the [`@DataClassName`](https://pub.dev/documentation/drift/latest/drift/DataClassName-class.html)
annotation to set the desired name.

### Json Serialization

By default, drift generates a `toJson` and `fromJson` method for each data class. These methods can be used to serialize and deserialize the data class to and from JSON. The names of the generated keys are the same as the column names in the table. 

To update the name of a column when serializing data to json, annotate the getter with [`@JsonKey`](https://pub.dev/documentation/drift/latest/drift/JsonKey-class.html).


## Custom Data Classes

If you want to use your own data classes, you can tell drift to use them instead of generating its own. This can be useful if you want to use a specific serialization library or if you want to use a specific type hierarchy.

To use a custom row class, simply annotate your table definition with `@UseRowClass`.

{{ load_snippet('start','lib/snippets/custom_row_classes/default.dart.excerpt.json','lib/snippets/custom_row_classes/named.dart.excerpt.json') }}



## Existing row classes

By default, drift generates a row class for each table. This row class can be used to access all columns, it also
implements `hashCode`, `operator==` and a few other useful operators.
When you want to use your own type hierarchy, or have more control over the generated classes, you can
also tell drift to your own class or type:

{{ load_snippet('custom-type','lib/snippets/dart_api/tables.dart.excerpt.json') }}

Drift verifies that the type is suitable for storing a row of that table.
More details about this feature are [described here](../custom_row_classes.md).

