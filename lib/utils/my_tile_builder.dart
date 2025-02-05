import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

Widget myTileBuilder(
    BuildContext context,
    Widget tileWidget,
    TileImage tile,
    ) {
  return ColorFiltered(
    colorFilter: const ColorFilter.matrix(<double>[
      -0.2126, -0.7152, -0.0722, 0, 255, // Red channel
      -0.2126, -0.7152, -0.0722, 0, 255, // Green channel
      -0.2126, -0.7152, -0.0722, 0, 255, // Blue channel
      0,       0,       0,       1, 0,   // Alpha channel
    ]),
    child: tileWidget,
  );
}
