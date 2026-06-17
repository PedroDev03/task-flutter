import 'package:flutter_test/flutter_test.dart';

import 'package:hello_world/main.dart';
import 'package:hello_world/database/memory_storage_service.dart';

void main() {
  testWidgets('Medication reminder smoke test', (WidgetTester tester) async {
    final storage = MemoryStorageService();
    await storage.init();
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(storage: storage, initialLoggedIn: false));
    await tester.pumpAndSettle();

    // Verify that our medications are listed on the home screen.
    expect(find.text('Medicamentos do Dia'), findsOneWidget);
    expect(find.text('Paracetamol 750mg'), findsOneWidget);
    expect(find.text('Ibuprofeno 600mg'), findsOneWidget);
  });
}

