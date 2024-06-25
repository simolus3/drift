import 'package:devtools_app_shared/ui.dart';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

import 'src/details.dart';
import 'src/list.dart';

void main() {
  runApp(const ProviderScope(child: DriftDevToolsExtension()));

  if (kDebugMode) {
    Logger.root.level = Level.FINE;
    Logger.root.onRecord.listen((record) {
      debugPrint(
          '[${record.level.name}] ${record.loggerName}: ${record.message}');
    });
  }
}

class DriftDevToolsExtension extends StatelessWidget {
  const DriftDevToolsExtension({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevToolsExtension(child: DriftDevtoolsBody());
  }
}

class DriftDevtoolsBody extends ConsumerWidget {
  const DriftDevtoolsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDatabase);

    return SplitPane(
      axis: SplitPane.axisFor(context, 0.85),
      initialFractions: const [1 / 3, 2 / 3],
      children: [
        const RoundedOutlinedBorder(
          child: Column(
            children: [
              AreaPaneHeader(
                roundedTopBorder: false,
                includeTopBorder: false,
                title: Text('Drift databases'),
                actions: [
                  _InfoButton(),
                ],
              ),
              Expanded(child: DatabaseList()),
            ],
          ),
        ),
        RoundedOutlinedBorder(
          clip: true,
          child: Column(children: [
            AreaPaneHeader(
              roundedTopBorder: false,
              includeTopBorder: false,
              title: selected != null
                  ? Text('Inspecting ${selected.typeName}')
                  : const Text('No database selected'),
            ),
            if (selected != null) const Expanded(child: DatabaseDetails())
          ]),
        ),
      ],
    );
  }
}

class _InfoButton extends StatelessWidget {
  const _InfoButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.info_outline),
      onPressed: () {
        showAboutDialog(
          context: context,
          applicationName: 'Drift extensions for DevTools',
          children: [
            Text.rich(
              TextSpan(
                children: [
                  _text(
                    'This extension allows inspecting a drift database in '
                    'DevTools. If you have ideas for additional functionality '
                    'that could be provided here, please ',
                  ),
                  _link('opening an issue',
                      'https://github.com/simolus3/drift/issues/new'),
                  _text(
                      'to make suggestions.\nAlso, thanks to Koen Van Looveren for writing '),
                  _link('drift_db_viewer',
                      'https://github.com/vanlooverenkoen/db_viewer/'),
                  const TextSpan(text: ' which is used to show the database.'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static TextSpan _text(String content) {
    return TextSpan(text: content);
  }

  static TextSpan _link(String content, String uri) {
    return TextSpan(
      text: content,
      style: const TextStyle(
        decoration: TextDecoration.underline,
      ),
      recognizer: TapGestureRecognizer()
        ..onTap = () async {
          await launchUrl(Uri.parse(uri));
        },
    );
  }
}
