import '../compiler.dart';

final class OrderBy implements SqlComponent {
  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addOrderBy(this);
  }
}
