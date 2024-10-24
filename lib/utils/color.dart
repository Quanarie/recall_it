import 'package:flutter/material.dart';

Color hexToColor(String hexColor) {
  return Color(int.parse(hexColor, radix: 16));
}

String colorToHex(Color color) {
  return '${color.alpha.toRadixString(16).padLeft(2, '0')}'
      '${color.red.toRadixString(16).padLeft(2, '0')}'
      '${color.green.toRadixString(16).padLeft(2, '0')}'
      '${color.blue.toRadixString(16).padLeft(2, '0').toUpperCase()}';
}
