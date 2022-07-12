import 'package:flutter/material.dart';
import 'package:vector_icon_generator/utils.dart';

class IconColorNotifier extends ChangeNotifier {
  Color _iconColor = Colors.white;

  Color get iconColor {
    if (_iconColor == Colors.white && !Utils.isDark) {
      _iconColor = Colors.black;
    } else if (_iconColor == Colors.black && Utils.isDark) {
      _iconColor = Colors.white;
    }
    return _iconColor;
  }

  void setColor(Color color) {
    _iconColor = color;
    notifyListeners();
  }

  void resetColor() {
    _iconColor = Utils.isDark ? Colors.white : Colors.black;
    notifyListeners();
  }
}
