import 'package:drift_workmanager_bug/drift_context.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask(
    (task, inputData) async {
      await DriftContext.test();
      return true;
    },
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _foregroundRunning = false;
  var _backgroundRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Align(
        alignment: Alignment.center,
        child: Row(
          children: [
            TextButton(
              onPressed: () async {
                setState(() => _foregroundRunning = true);
                await DriftContext.test();
                setState(() => _foregroundRunning = false);
              },
              child: Text('Test FG'),
            ),
            TextButton(
              onPressed: () async {
                setState(() => _backgroundRunning = true);
                await Workmanager().registerOneOffTask('foo', 'bar');
                setState(() => _backgroundRunning = false);
              },
              child: Text('Test BG'),
            ),
          ],
        ),
      ),
    );
  }
}
