import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import 'home/card.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  String _text = '';
  Future<List<TodoEntryWithCategory>>? _search;

  @override
  void initState() {
    _controller.addListener(() {
      setState(() {
        if (_text != _controller.text && _controller.text.isNotEmpty) {
          _text = _controller.text;
          _search = ref.read(AppDatabase.provider).search(_text);
        }
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'Search for todos across all categories',
          ),
          textInputAction: TextInputAction.search,
          controller: _controller,
        ),
      ),
      body: _search == null
          ? const Align(
              alignment: Alignment.center,
              child: Text('Enter text to start searching'),
            )
          : FutureBuilder<List<TodoEntryWithCategory>>(
              future: _search,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final results = snapshot.data!;

                  return ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      return TodoCard(results[index].entry);
                    },
                  );
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
    );
  }
}
