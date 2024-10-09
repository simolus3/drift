drift_sqflite not working with BigInt
Use BigInt in expressions
add datetime storage migration docs


Type converters and json serialization
By default, type converters only apply to the conversion from Dart to the database. They don't impact how values are serialized to and from JSON. If you want to apply the same conversion to JSON as well, make your type converter mix-in the JsonTypeConverter class. You can also override the toJson and fromJson methods to customize serialization as long as the types stay the compatible. The type converter returned by TypeConverter.json already implements JsonTypeConverter, so it will apply to generated row classes as well.

Indataclass docs