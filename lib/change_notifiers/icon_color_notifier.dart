import 'package:flutter/material.dart';
import 'package:vector_icon_generator/utils/global_data.dart';

class IconColorNotifier extends ChangeNotifier {
  Color _iconColor = Colors.white;

  Color get iconColor {
    if (_iconColor == Colors.white && !GlobalData.isDark) {
      _iconColor = Colors.black;
    } else if (_iconColor == Colors.black && GlobalData.isDark) {
      _iconColor = Colors.white;
    }
    return _iconColor;
  }

  void setColor(Color color) {
    _iconColor = color;
    notifyListeners();
  }

  void resetColor() {
    _iconColor = GlobalData.isDark ? Colors.white : Colors.black;
    notifyListeners();
  }
}
