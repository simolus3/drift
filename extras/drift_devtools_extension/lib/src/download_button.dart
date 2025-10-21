import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart';
import 'details.dart';

class DownloadDatabaseButton extends ConsumerStatefulWidget {
  final bool isEnabled;

  const DownloadDatabaseButton({
    super.key,
    this.isEnabled = false,
  });

  @override
  ConsumerState<DownloadDatabaseButton> createState() =>
      _DownloadDatabaseButtonState();
}

class _DownloadDatabaseButtonState
    extends ConsumerState<DownloadDatabaseButton> {
  Future<void>? _pendingDownload;

  void saveFile(String databaseName, String encodedData) {
    // adapted from https://github.com/flutter/devtools/blob/98a52a86231144d8ed31cf9ab7e2165a8f23f925/packages/devtools_app/lib/src/shared/config_specific/import_export/_export_web.dart#L16
    // ideally, this would use ExportController. see: https://github.com/flutter/devtools/issues/9451
    final element = document.createElement('a') as HTMLAnchorElement;

    element.setAttribute(
        'href', "data:application/octet-stream;base64,$encodedData");
    element.setAttribute('download', "$databaseName.sqlite");
    element.style.display = 'none';

    (document.body as HTMLBodyElement).append(element);
    element.click();
    element.remove();
  }

  @override
  Widget build(BuildContext context) {
    return DevToolsButton(
      tooltip: widget.isEnabled
          ? null
          : "Downloading is not enabled on this platform",
      onPressed: _pendingDownload != null || !widget.isEnabled
          ? null
          : () {
              setState(() {
                _pendingDownload = Future(() async {
                  final database = ref.read(loadedDatabase);
                  final res = await database.value!.download();

                  saveFile(res["database"]!, res["data"]!);
                })
                    .whenComplete(() => setState(() => _pendingDownload = null))
                    .then((_) {});
              });
            },
      label: 'Download database',
      icon: Icons.download,
    );
  }
}
