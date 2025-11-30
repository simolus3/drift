import 'package:jaspr/jaspr.dart';
import 'package:jaspr_riverpod/jaspr_riverpod.dart';

export 'platform_unsupported.dart'
    if (dart.library.js_interop) 'platform_web.dart';
import 'platform_unsupported.dart'
    if (dart.library.js_interop) 'platform_web.dart';

/// Installs a [ProviderScope] for `@client` components.
///
/// Because each client uses its own scope, the scope is configured to use a
/// shared static root container so that the individual components can share
/// state.
final class ClientComponentScope extends StatelessComponent {
  final Component child;

  ClientComponentScope({super.key, required this.child});

  @override
  Component build(BuildContext context) {
    return ProviderScope(child: child, customRoot: rootContainer);
  }
}
