import 'package:flutter/material.dart';
import 'package:example/bloc.dart';
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
          typography: Typography.material2018(),
        ),
        home: HomeScreen(),
      ),
    );
  }
}
