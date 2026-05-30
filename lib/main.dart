import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/supabase_storage_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  if (!kIsWeb) {
    AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'alerts',
          channelName: 'Alertas de Medicamentos',
          channelDescription: 'Notificações para lembretes de medicamentos',
          defaultColor: Colors.teal.shade400,
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

  final storage = SupabaseStorageService();
  await storage.init();
  
  final authService = AuthService();
  final isLoggedIn = await authService.isLoggedIn();

  runApp(MyApp(storage: storage, initialLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final SupabaseStorageService storage;
  final bool initialLoggedIn;

  const MyApp({super.key, required this.storage, required this.initialLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lembrete de Medicamentos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          primary: Colors.teal.shade700,
          secondary: Colors.tealAccent.shade700,
        ),
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
      ),
      home: initialLoggedIn ? HomeScreen(storage: storage) : LoginScreen(storage: storage),
    );
  }
}
