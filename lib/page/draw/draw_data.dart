import 'package:flutter/material.dart';

typedef ColorMap = Map<String, Color> ;

extension Ext on ColorMap {
  Color get defaultColor => this['default']!;
}

class DrawEntity {
  final List<Offset> offset;
  final Color color;
  final double strokeWidth;

  DrawEntity(Offset from, {
    this.color = Colors.black,
    this.strokeWidth = 3.0
  }): offset = [from];

  void to(Offset next) {
    offset.add(next);
  }
}