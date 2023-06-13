class FatalWarningException implements Exception {
  const FatalWarningException();

  @override
  String toString() {
    return 'Drift emitted warnings and the `fatal_warnings` build option is '
        'enabled.';
  }
}
