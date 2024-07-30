---

title: Dataclasses
description: The generated data classes for each table in your database.

---

Drift generates a data class for each table.
These data classes are used to represent a row in the table and are used to interact with the database.

These dataclasses have all the usual features you'd expect from a data class, like `fromJson`, `toJson`, `copyWith`, `toString`, `hashCode`, and `operator==`.

In addition to these methods, drift also generates a `toCompanion` method which returns a companion object that can be used to insert or update a row in the table.

### Dataclass Name

{{ load_snippet('custom-data-class-name','lib/snippets/dart_api/tables.dart.excerpt.json') }}

By default, drift will strip a trailing `s` from the table name (e.g. The `Users` table would have a `User` data class).   

That doesn't work well in all cases. For instance `EnabledCategories` class from above, we'd get
a `EnabledCategorie` data class. In those cases, you can use the [`@DataClassName`](https://pub.dev/documentation/drift/latest/drift/DataClassName-class.html)
annotation to set the desired name.

### Json Serialization

By default, drift generates a `toJson` and `fromJson` method for each data class. These methods can be used to serialize and deserialize the data class to and from JSON. The names of the generated keys are the same as the column names in the table. 

To update the name of a column when serializing data to json, annotate the getter with [`@JsonKey`](https://pub.dev/documentation/drift/latest/drift/JsonKey-class.html).

{{ load_snippet('custom-json-key','lib/snippets/dart_api/tables.dart.excerpt.json') }}

## Companions

Drift generates a companion object for each data class which is used to insert or update a row in the table.

This Companion Class is generated for custom dataclasses as well.

{{ load_snippet('companion-custom-class','lib/snippets/custom_row_classes/default.dart.excerpt.json','lib/snippets/custom_row_classes/named.dart.excerpt.json') }}

<div class="annotate" markdown>

!!! note "What are these `Value(...)` things?"
    
    All optional fields must be wrapped in a `Value(...)` object when using the companion object.  
    This is used to differentiate between an unset value [`Value.absent()`] and a `null` value [`Value(null)`] (1)

</div>

1. If we didn't know the difference between `null` and `absent`, then on a column which
    1. could store `null` and
    2. has a default value

    we wouldn't be able to tell if the value was set to `null` or if it was never set at all, in which case the default value should be used.

    
## Custom Data Classes

!!! note "Why Should I Use A Custom Data Class?"

    If your only reason for using a custom data class is to add methods to the generated data class, use an extension method instead:

    {{ load_snippet('extention-on-data-class','lib/snippets/dart_api/tables.dart.excerpt.json', indent=4) }}
    
    However, there are a few reasons you might want to use a custom data class:

    - **Serialization**: If you want to use a specific serialization library, you can use a custom data class to define how the data should be serialized.
    - **Type Hierarchy**: If you want to use a specific type hierarchy, you can use a custom data class to define the type hierarchy.
    - **Reduce Generated Code**: If you want to reduce the amount of generated code, you can use a custom data class to define only the fields and methods you need.

If you want to use your own data classes, you can tell drift to use them instead of generating its own. This can be useful if you want to use a specific serialization library or if you want to use a specific type hierarchy.

To use a custom data class, simply annotate your table definition with `@UseRowClass`.

{{ load_snippet('start','lib/snippets/custom_row_classes/default.dart.excerpt.json','lib/snippets/custom_row_classes/named.dart.excerpt.json') }}

Records can also be used as custom data classes:

{{ load_snippet('record','lib/snippets/custom_row_classes/default.dart.excerpt.json','lib/snippets/custom_row_classes/named.dart.excerpt.json') }}

### Required Fields

In order for drift to recognize your custom data class, any required fields must be named the same as the columns in the table.
The custom data class can have additional fields that are not present in the table as long as they are not required.
Any fields on the table that are not present in the custom data class will be ignored.

{{ load_snippet('ignored','lib/snippets/custom_row_classes/default.dart.excerpt.json','lib/snippets/custom_row_classes/named.dart.excerpt.json') }}

### Named/Static/Async Constructors

By default, drift will use the default, unnamed constructor to map a row to the class.
If you want to use another constructor, set the `constructor` parameter on the
`@UseRowClass` annotation.
You can even use a static or asynchronous constructor, as long as there are no required fields that need to be set.

{{ load_snippet('async','lib/snippets/custom_row_classes/default.dart.excerpt.json','lib/snippets/custom_row_classes/named.dart.excerpt.json') }}




