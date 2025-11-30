import 'package:jaspr/jaspr.dart';

/// Renders a warning message on debug builds and fails the build on release
/// mode.
final class BrokenComponent extends StatelessComponent {
  final String message;

  BrokenComponent(this.message);

  @override
  Component build(BuildContext context) {
    if (kDebugMode) {
      return strong(styles: Styles(color: Colors.red), [text(message)]);
    } else {
      throw StateError('Cannot build BrokenComponent: $message');
    }
  }
}
