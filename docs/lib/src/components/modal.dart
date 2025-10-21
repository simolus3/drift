import 'package:jaspr/jaspr.dart';
import 'package:jaspr_riverpod/jaspr_riverpod.dart';
import 'package:universal_web/web.dart' as web;

import '../platform_specific.dart';

typedef ModalState = ({bool sidebarOpen, bool searchOpen});

final class ModalNotifier extends Notifier<ModalState> {
  @override
  ModalState build() {
    return (sidebarOpen: false, searchOpen: false);
  }

  void showSearch() {
    ref.container;
    state = (searchOpen: true, sidebarOpen: false);
    web.document.body!.classList.add('modal-open');
  }

  void hideModals() {
    web.document.body!.classList.remove('modal-open');
    state = (searchOpen: false, sidebarOpen: false);
  }

  static final provider = NotifierProvider(ModalNotifier.new);
}

/// Renders as a gray background darkening content while a modal is open.
@client
final class Backdrop extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    return ClientComponentScope(
      child: Builder(
        builder: (context) {
          final state = context.watch(ModalNotifier.provider);
          if (state.sidebarOpen || state.searchOpen) {
          } else {
            return const Component.empty();
          }

          return div(
            classes: 'modal-backdrop fade show',
            events: {
              'click': (_) =>
                  context.read(ModalNotifier.provider.notifier).hideModals(),
            },
            [],
          );
        },
      ),
    );
  }
}
