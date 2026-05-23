import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'screens/home_screen.dart';
import 'database/memory_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'alerts',
          channelName: 'Alertas de Medicamentos',
          channelDescription: 'Notificações para lembretes de medicamentos',
          defaultColor: const Color.fromRGBO(147, 207, 184, 1),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        )
      ],
      debug: true
    );
  }

  final storage = MemoryStorageService();
  await storage.init();
  runApp(MyApp(storage: storage));
}

class MyApp extends StatelessWidget {
  final MemoryStorageService storage;

  const MyApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lembrete de Medicamentos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(147, 207, 184, 1),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: HomeScreen(storage: storage),
    );
  }
}
