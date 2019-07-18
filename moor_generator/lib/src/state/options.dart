class MoorOptions {
  final bool generateFromJsonStringConstructor;

  MoorOptions(this.generateFromJsonStringConstructor);

  const MoorOptions.defaults() : generateFromJsonStringConstructor = false;
}
