part of '../analysis.dart';

/// A type that sql expressions can have at runtime.
abstract class SqlType {}

class NullType extends SqlType {}

class IntegerType extends SqlType {}

class RealType extends SqlType {}

class TextType extends SqlType {}

class BlobType extends SqlType {}

/// Provides more precise hints than the [SqlType]. For instance, booleans are
/// stored as ints in sqlite, but it might be desirable to know whether an
/// expression will actually be a boolean.
abstract class TypeHint {}

class IsBoolean extends TypeHint {}

class IsDateTime extends TypeHint {}
