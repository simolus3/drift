import 'dart:js_interop_unsafe';

import 'package:web/web.dart';
import 'dart:js_interop';

import 'common.dart';

const key = 'hidden_announcement';

void watchAnnouncementBar() {
  final hidden = window.localStorage.getItem(key);

  for (final node in findComponents('announce').toList()) {
    if (node.instanceOfString('Element')) {
      final element = node as HTMLElement;
      if (element.childElementCount == 0) {
        continue;
      }

      final id = (element.dataset['id'] as JSString).toDart;
      final shouldHide = id == hidden;

      if (shouldHide) {
        element.hidden = true.toJS;
      } else {
        final closeButton =
            element.querySelector('.md-typeset > :first-child')!;
        closeButton.onClick.listen((_) {
          window.localStorage.setItem(key, id);
          element.hidden = true.toJS;
        });
      }
    }
  }
}
