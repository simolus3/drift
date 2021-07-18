part of 'declaration.dart';

/// Declaration of a database or dao in a Dart file.
class DatabaseOrDaoDeclaration implements DartDeclaration {
  /// The [ClassElement] with the `UseMoor` or `UseDao` annotation.
  final ClassElement fromClass;
  @override
  final SourceRange declaration;

  DatabaseOrDaoDeclaration._(this.fromClass, this.declaration);

  factory DatabaseOrDaoDeclaration(ClassElement fromClass, FoundFile file) {
    return DatabaseOrDaoDeclaration._(
      fromClass,
      SourceRange.fromElementAndFile(fromClass, file),
    );
  }

  @override
  Element get element => fromClass;
}
