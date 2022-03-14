import 'package:flutter/material.dart';
import 'package:example/bloc.dart';
import 'package:provider/provider.dart';
import 'widgets/homescreen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Provider<TodoAppBloc>(
      create: (_) => TodoAppBloc(),
      dispose: (_, bloc) => bloc.close(),
      child: MaterialApp(
        title: 'Drift Demo',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          typography: Typography.material2018(),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
