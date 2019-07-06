import 'package:example_web/database/database.dart';
import 'package:flutter_web/material.dart';

import '../main.dart';

class SliverEntryList extends StatelessWidget {
  final Stream<List<Entry>> entries;

  const SliverEntryList({Key key, this.entries}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Entry>>(
      stream: entries,
      builder: (context, snapshot) {
        final entries = snapshot.data ?? const [];

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final entry = entries[index];

              return _EntryCard(
                key: ObjectKey(entry.id),
                entry: entry,
              );
            },
            childCount: entries.length,
          ),
        );
      },
    );
  }
}

class _EntryCard extends StatelessWidget {
  final Entry entry;

  const _EntryCard({Key key, this.entry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(entry.content),
          Spacer(),
          Checkbox(
            value: entry.done,
            onChanged: (checked) {
              DatabaseProvider.provide(context).setCompleted(entry, checked);
            },
          ),
        ],
      ),
    );
  }
}
