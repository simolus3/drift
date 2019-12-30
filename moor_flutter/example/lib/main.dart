import 'package:flutter/material.dart';
import 'package:moor_example/bloc.dart';
import 'package:provider/provider.dart';
import 'widgets/homescreen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider<TodoAppBloc>(
      create: (_) => TodoAppBloc(),
      dispose: (_, bloc) => bloc.close(),
      child: MaterialApp(
        title: 'moor Demo',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          // use the good-looking updated material text style
          typography: Typography(
            englishLike: Typography.englishLike2018,
            dense: Typography.dense2018,
            tall: Typography.tall2018,
          ),
        ),
        home: HomeScreen(),
      ),
    );
  }
}
