//@dart=2.9
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
      fromClass != null
          ? SourceRange.fromElementAndFile(fromClass, file)
          : null,
    );
  }

  @override
  Element get element => fromClass;
}
