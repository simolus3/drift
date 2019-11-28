class EngineOptions {
  /// Moor extends the sql grammar a bit to support type converters and other
  /// features. Enabling this flag will make this engine parse sql with these
  /// extensions enabled.
  final bool useMoorExtensions;

  /// Enables functions declared in the `json1` module for analysis
  final bool enableJson1;

  EngineOptions(this.useMoorExtensions, this.enableJson1);
}
