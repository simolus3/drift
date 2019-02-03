class GenerationContext {
  StringBuffer buffer = StringBuffer();
  List<dynamic> boundVariables = List();

  void addBoundVariable(dynamic data) {
    boundVariables.add(data);
  }
}
