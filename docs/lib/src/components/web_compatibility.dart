import 'package:jaspr/jaspr.dart';

import '../platform_specific.dart';

@client
final class WebCompatibilityCheck extends StatefulComponent {
  @override
  State<StatefulComponent> createState() => _WebCompatibilityCheckState();
}

final class _WebCompatibilityCheckState extends State<WebCompatibilityCheck> {
  Future<String>? _compatibilityResult;

  void startCheck() {
    setState(() {
      _compatibilityResult ??= determineDriftWasmCompatibility();
    });
  }

  @override
  Component build(BuildContext context) {
    return FutureBuilder(
      future: _compatibilityResult,
      builder: (context, snapshot) {
        return div([
          if (_compatibilityResult == null) ...[
            button(classes: 'compat', [
              text('Check compatibility'),
            ], onClick: startCheck),
            pre([text('Compatibility check not started yet.')]),
          ] else if (snapshot.connectionState == ConnectionState.waiting)
            text('Loading...')
          else if (snapshot.hasError)
            pre([
              text('Error: ${snapshot.error}, Trace:\n${snapshot.stackTrace}'),
            ])
          else
            pre([text(snapshot.data ?? 'No results available')]),
        ]);
      },
    );
  }
}
