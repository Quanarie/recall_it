import 'package:flutter/material.dart';
import 'package:recall_it/utils/color.dart';

class ColorPicker extends StatelessWidget {
  final Function(Color) onColorSelected;

  ColorPicker({super.key, required this.onColorSelected});

  final List<Color> availableColors = [
    hexToColor('FF4CA5B7'),
    hexToColor('FF4D7A4E'),
    hexToColor('FFDA4F8C'),
    hexToColor('FF8750D3'),
    Colors.black87,
    Colors.white,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: availableColors.map((color) {
        return _buildColorOption(color);
      }).toList(),
    );
  }

  Widget _buildColorOption(Color color) {
    return GestureDetector(
      onTap: () => onColorSelected(color),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: hexToColor('FF689198'), width: 4),
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
      ),
    );
  }
}
