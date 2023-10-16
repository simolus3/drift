import 'package:devtools_app_shared/ui.dart';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/details.dart';
import 'src/list.dart';

void main() {
  runApp(const ProviderScope(child: DriftDevToolsExtension()));
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

    return Split(
      axis: Split.axisFor(context, 0.85),
      initialFractions: const [1 / 3, 2 / 3],
      children: [
        const RoundedOutlinedBorder(
          child: Column(
            children: [
              AreaPaneHeader(
                roundedTopBorder: false,
                includeTopBorder: false,
                title: Text('Drift databases'),
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
                  ? Text(selected.typeName)
                  : const Text('No database selected'),
            ),
            if (selected != null) const Expanded(child: DatabaseDetails())
          ]),
        ),
      ],
    );
  }
}
