import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;

  bool get isDarkMode {
    if (themeMode == ThemeMode.system) {
      // O modo do sistema pode não estar imediatamente disponível aqui sem contexto,
      // mas podemos assumir falso ou usar o scheduler.
      // O ideal é usar o binding.
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return themeMode == ThemeMode.dark;
  }

  void toggleTheme(bool isOn) {
    themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
