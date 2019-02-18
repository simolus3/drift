/// Use this class as an annotation to inform sally_generator that a database
/// class should be generated using the specified [UseSally.tables].
class UseSally {
  /// The tables to include in the database
  final List<Type> tables;

  /// Use this class as an annotation to inform sally_generator that a database
  /// class should be generated using the specified [UseSally.tables].
  const UseSally({this.tables});
}
