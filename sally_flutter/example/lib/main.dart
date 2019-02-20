import 'package:flutter/material.dart';
import 'database.dart';
import 'widgets/homescreen.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() {
    return MyAppState();
  }
}

class MyAppState extends State<MyApp> {

  Database _db;

  @override
  void initState() {
    _db = Database();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DatabaseProvider(
      db: _db,
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

class DatabaseProvider extends InheritedWidget {

  final Database db;

  DatabaseProvider({@required this.db, Widget child}) : super(child: child);

  @override
  bool updateShouldNotify(DatabaseProvider oldWidget) {
    return oldWidget.db != db;
  }

  static Database provideDb(BuildContext ctx) => (ctx.inheritFromWidgetOfExactType(DatabaseProvider) as DatabaseProvider).db;
}