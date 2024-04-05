import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:manager/database.dart';
import 'package:manager/pages/listings.dart';
import 'package:manager/pages/owners.dart';
import 'package:manager/pages/product.dart';
import 'package:manager/pages/store.dart';

late final AppDatabase db;
void main() {
  db = AppDatabase();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manager Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Home(),
    );
  }
}

class Home extends HookConsumerWidget {
  const Home({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = useTabController(initialLength: 4);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Demo'),
        bottom: TabBar(
          controller: tabs,
          tabs: const [
            Tab(text: 'Products'),
            Tab(text: 'Listings'),
            Tab(text: 'Stores'),
            Tab(text: 'Owners'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabs,
        children: const [
          ProductPage(),
          ListingPage(),
          StorePage(),
          OwnersPage(),
        ],
      ),
    );
  }
}
