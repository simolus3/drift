import 'package:drift_website/src/search/database.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_riverpod/jaspr_riverpod.dart';
import 'package:universal_web/web.dart' as web;

import '../components/modal.dart';
import '../platform_specific.dart';
import 'state.dart';

final class SearchModalImpl extends StatelessComponent {
  @override
  Component build(BuildContext _) {
    return ClientComponentScope(
      child: Builder(
        builder: (context) {
          final shouldShow = context.watch(ModalNotifier.provider).searchOpen;
          if (!shouldShow) {
            return const Component.empty();
          }

          return div(
            classes: 'modal fade show',
            styles: Styles(display: Display.block),
            events: {
              'click': (event) {
                final target = event.target;
                if (target case web.HTMLDivElement div) {
                  if (div.className == 'modal fade show') {
                    // The outer modal backdrop was clicked (not the modal
                    // dialog ocntent). Hide the component.
                    context.read(ModalNotifier.provider.notifier).hideModals();
                  }
                }
              },
              'keyup': (event) {
                switch ((event as web.KeyboardEvent).key) {
                  case 'ArrowUp':
                    context
                        .read(SearchResultsNotifier.provider.notifier)
                        .activeUp();
                  case 'ArrowDown':
                    context
                        .read(SearchResultsNotifier.provider.notifier)
                        .activeDown();
                  case 'Enter':
                    if (context.read(SearchResultsNotifier.provider)
                        case AsyncData(value: SearchResults(:final active?))) {
                      web.window.location.href = active.path;
                    }
                }
              },
            },
            attributes: {'tabindex': '-1'},
            [
              div(classes: 'modal-dialog', [
                div(classes: 'modal-content', [
                  div(classes: 'modal-header', [const _SearchInput()]),
                  div(classes: 'modal-body', [const _SearchResults()]),
                  div(classes: 'modal-footer', [
                    small([text('Search built with fts5')]),
                  ]),
                ]),
              ]),
            ],
          );
        },
      ),
    );
  }
}

final class _SearchInput extends StatefulComponent {
  const _SearchInput();

  @override
  State<StatefulComponent> createState() => _SearchInputState();
}

final class _SearchInputState extends State<_SearchInput> {
  @override
  void initState() {
    super.initState();

    context.binding.addPostFrameCallback(() {
      final field =
          web.document.getElementById('search-field') as web.HTMLInputElement;
      field.focus();
    });
  }

  @override
  Component build(BuildContext context) {
    return input(
      classes: 'form-control form-control-lg bg-info-subtle',
      type: InputType.search,
      id: 'search-field',
      attributes: {'placeholder': 'Search this site…'},
      value: context.watch(SearchTermNotifier.provider),
      onInput: (value) {
        context
            .read(SearchTermNotifier.provider.notifier)
            .search(value as String);
      },
    );
  }
}

final class _SearchResults extends StatelessComponent {
  const _SearchResults();

  @override
  Component build(BuildContext context) {
    final term = context.watch(SearchTermNotifier.provider);
    final results = context.watch(SearchResultsNotifier.provider);

    if (term.length < 3) {
      return em([text('Start typing to view search results')]);
    }

    switch (results) {
      case AsyncLoading<SearchResults>():
        return div(classes: 'd-flex justify-content-center', [
          div(
            classes: 'spinner-border',
            attributes: {'role': 'status'},
            [
              div(classes: 'visually-hidden', [text('Loading search results')]),
            ],
          ),
        ]);

      case AsyncData<SearchResults>(:final value):
        return div(classes: 'list-group', [
          for (final item in value.results)
            _ResultItem(key: ValueKey(item), result: item),
        ]);
      case AsyncError<SearchResults>(:final error, :final stackTrace):
        return pre([
          code([
            text('''
Could not load results: $error

$stackTrace
'''),
          ]),
        ]);
    }
  }
}

final class _ResultItem extends StatelessComponent {
  final SearchResult result;

  _ResultItem({super.key, required this.result});

  @override
  Component build(BuildContext context) {
    final matches = _startEndRegex.allMatches(result.highlight);
    var highlightItems = <Component>[];
    var textOffset = 0;
    var isInMatch = false;
    for (final match in matches) {
      var offset = match.start;
      if (textOffset < offset) {
        final str = result.highlight.substring(textOffset, offset);

        highlightItems.add(
          isInMatch
              ? span(classes: 'fw-bold text-success-emphasis', [text(str)])
              : text(str),
        );
      }

      textOffset = match.end;
      isInMatch = match.group(0)! == 'SNIPSTART';
    }
    if (textOffset < result.highlight.length) {
      highlightItems.add(text(result.highlight.substring(textOffset)));
    }

    final snapshot = context.watch(SearchResultsNotifier.provider);
    final isActive = switch (snapshot) {
      AsyncData(value: SearchResults(:final active)) => active == result,
      _ => false,
    };

    return a(
      href: result.path,
      classes:
          'list-group-item list-group-item-action d-flex${isActive ? ' active' : ''}',
      events: {
        'mouseenter': (e) {
          context.read(SearchResultsNotifier.provider.notifier).activeResult =
              result;
        },
      },
      [
        div(classes: 'ms-2 me-auto', [
          div(classes: 'fw-bold', [text(result.title)]),
          span(highlightItems),
        ]),
      ],
    );
  }

  static final _startEndRegex = RegExp(r'SNIPSTART|SNIPEND');
}
