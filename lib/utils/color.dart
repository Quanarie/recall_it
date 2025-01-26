import 'package:flutter/material.dart';

Color hexToColor(String hexColor) {
  return Color(int.parse(hexColor, radix: 16));
}

String colorToHex(Color color) {
  return '${(color.a * 255).toInt().toRadixString(16).padLeft(2, '0')}'
      '${(color.r * 255).toInt().toRadixString(16).padLeft(2, '0')}'
      '${(color.g * 255).toInt().toRadixString(16).padLeft(2, '0')}'
      '${(color.b * 255).toInt().toRadixString(16).padLeft(2, '0').toUpperCase()}';
}
