class RequiredVariables {
  final Set<int> requiredNumberedVariables;
  final Set<String> requiredNamedVariables;

  const RequiredVariables(
      this.requiredNumberedVariables, this.requiredNamedVariables);

  static const RequiredVariables empty = RequiredVariables({}, {});
}
