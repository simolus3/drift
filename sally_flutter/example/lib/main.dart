import 'package:flutter/material.dart';
import 'package:sally_example/bloc.dart';
import 'package:sally_example/widgets/homescreen.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() {
    return MyAppState();
  }
}

class MyAppState extends State<MyApp> {

  TodoBloc _bloc;

  @override
  void initState() {
    _bloc = TodoBloc();
    super.initState();
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      bloc: _bloc,
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.purple,
        ),
        home: HomeScreen(),
      ),
    );
  }
}

class BlocProvider extends InheritedWidget {

  final TodoBloc bloc;

  BlocProvider({@required this.bloc, Widget child}) : super(child: child);

  @override
  bool updateShouldNotify(BlocProvider oldWidget) {
    return oldWidget.bloc != bloc;
  }

  static TodoBloc provideBloc(BuildContext ctx) => (ctx.inheritFromWidgetOfExactType(BlocProvider) as BlocProvider).bloc;
}