import 'package:flutter/material.dart';
import 'package:vector_icon_generator/utils/global_data.dart';

class DarkModeNotifier extends ChangeNotifier {
  bool _darkMode = true;

  bool get darkMode => _darkMode;

  void toggle() {
    _darkMode = !_darkMode;
    GlobalData.isDark = _darkMode;
    notifyListeners();
  }
}