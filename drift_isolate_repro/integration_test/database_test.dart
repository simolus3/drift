import 'package:drift_isolate_repro/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('Find the button (this works)', (tester) async {
      await tester.pumpWidget(const ProviderWrapper(child: MyApp()));

      final app = find.byType(DatabaseUser);
      expect(find.text('not started yet'), findsOneWidget);

      await tester.tap(app);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('done'), findsOneWidget);
    });

    testWidgets('Rebuild the Widget (this does not work)', (tester) async {
      await tester.pumpWidget(const ProviderWrapper(child: MyApp()));

      final app = find.byType(DatabaseUser);
      expect(find.text('not started yet'), findsOneWidget);

      await tester.tap(app);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('done'), findsOneWidget);
      await tester.pump();
    });
  });
}
