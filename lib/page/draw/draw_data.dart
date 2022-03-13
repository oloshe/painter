import 'dart:math';

import 'package:flutter/material.dart';

typedef ColorMap = Map<String, Color>;

const Color defaultBgColor = Colors.white;
const List<double> strokeWidths = [1, 3, 5, 7, 9, 12, 15];

const double minStroke = 1;
const double maxStroke = 50;

const defaultColors = [
  Colors.black,
  Colors.white,
  Colors.brown,
  Colors.blueGrey,
  Colors.red,
  Colors.pink,
  Colors.purple,
  Colors.deepPurple,
  Colors.indigo,
  Colors.blue,
  Colors.lightBlue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.lightGreen,
  Colors.lime,
  Colors.yellow,
  Colors.amber,
  Colors.orange,
  Colors.deepOrange,
];

extension Ext on ColorMap {
  Color get defaultColor => this['default']!;
}

class DrawEntity {
  final Path path;
  final Color color;
  final double strokeWidth;
  final bool clear;

  DrawEntity(
    Offset from, {
    this.color = Colors.black,
    this.strokeWidth = 3.0,
    this.clear = false,
  }) : path = Path()..moveTo(from.dx, from.dy);

  void to(Offset next) {
    path.lineTo(next.dx, next.dy);
  }

  void draw(Canvas canvas, Paint paint, Color bgColor) {
    paint.color = clear ? bgColor : color;
    paint.strokeWidth = strokeWidth;
    canvas.drawPath(path, paint);
  }

  // @override
  // bool operator ==(Object other) {
  //   return identical(this, other) ||
  //       (other is DrawEntity &&
  //           color == other.color &&
  //           strokeWidth == other.strokeWidth);
  // }
  //
  // @override
  // int get hashCode => Object.hash(
  //       super.hashCode,
  //       color,
  //       strokeWidth,
  //     );
}
