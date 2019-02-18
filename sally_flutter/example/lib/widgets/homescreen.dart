import 'package:flutter/material.dart';
import 'package:sally_example/database.dart';
import 'package:sally_example/main.dart';

// ignore_for_file: prefer_const_constructors

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.provideBloc(context);

    return Scaffold(
      drawer: Text('Hi'),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text('TODO List'),
          ),
          StreamBuilder<List<TodoEntry>>(
            stream: bloc.todosForHomepage,
            builder: (ctx, snapshot) {
              final data = snapshot.hasData ? snapshot.data : <TodoEntry>[];

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, index) => Text(data[index].content),
                  childCount: data.length,
                ),
              );
            },
          ),
        ],
      ),
      bottomSheet: Material(
        elevation: 12.0,
        child: TextField(
          onSubmitted: bloc.createTodoEntry,
        ),
      ),
    );
  }
}
