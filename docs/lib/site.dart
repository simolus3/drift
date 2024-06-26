import 'dart:html';

// ignore: non_constant_identifier_names
void built_site_main() {
  if (window.location.pathname?.startsWith('/search') == true) {
    final privacyTag = document.getElementById('privacy');
    void loadSearchResults() {
      privacyTag?.remove();

      final element = ScriptElement()
        ..async = true
        // ignore: unsafe_html
        ..src =
            'https://cse.google.com/cse.js?cx=002567324444333206795:_yptu7lact8';
      document.head?.append(element);
    }

    final storage = window.localStorage;

    // Only load search results after consent.
    if (storage.containsKey('google_ok')) {
      loadSearchResults();
    } else {
      privacyTag?.style.visibility = 'visible';
      document.getElementById('accept')?.onClick.first.whenComplete(() {
        storage['google_ok'] = '';
        loadSearchResults();
      });
    }
  }

  // Make the search box functional
  for (final element in document
      .querySelectorAll('.td-search-input')
      .whereType<InputElement>()) {
    element.onKeyPress.where((e) => e.keyCode == 13).first.whenComplete(() {
      final value = element.value;
      if (value != null && value.isNotEmpty) {
        window.location.assign('/search/?q=${Uri.encodeQueryComponent(value)}');
      }
    });
  }

  installTabBars();
  installCollapsibles();
}

void installTabBars() {
  for (final ul in window.document.querySelectorAll('.nav-tabs')) {
    final content = ul.nextElementSibling;
    if (content == null || content.className != 'tab-content') {
      continue;
    }

    final tabs = <(Element, Element)>[];

    void selectBody(Element selectedBody) {
      for (final (header, body) in tabs) {
        if (body == selectedBody) {
          header.classes.add('active');
          body.classes
            ..remove('fade')
            ..add('active')
            ..add('show');
        } else {
          header.classes.remove('active');
          body.classes
            ..remove('active')
            ..remove('show')
            ..add('fade');
        }
      }
    }

    for (final (i, header) in ul.children.skip(1).indexed) {
      final body = content.children[i];
      tabs.add((header.querySelector('button')!, body));

      header.onClick.listen((_) {
        selectBody(body);
      });
    }
  }
}

void installCollapsibles() {
  for (final collapsible in window.document.querySelectorAll('.collapsible')) {
    var expanded = false;

    collapsible.onClick.listen((_) {
      expanded = !expanded;

      if (expanded) {
        collapsible.classes.add('active');
      } else {
        collapsible.classes.remove('active');
      }
    });
  }
}
