import 'package:example_web/widgets/home_screen.dart';
import 'package:flutter_web/material.dart';

import 'database/database.dart';

void launchApp() {
  runApp(
    DatabaseProvider(
      db: Database(),
      child: MaterialApp(
        title: 'Moor web!',
        home: HomeScreen(),
      ),
    ),
  );
}

class DatabaseProvider extends InheritedWidget {
  final Database db;

  DatabaseProvider({@required this.db, @required Widget child})
      : super(child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;

  static Database provide(BuildContext ctx) {
    return (ctx.inheritFromWidgetOfExactType(DatabaseProvider)
            as DatabaseProvider)
        ?.db;
  }
}
