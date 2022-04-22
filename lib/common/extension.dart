import 'dart:core';

import 'package:flutter/material.dart';

extension DurationExt on int {
  Duration get seconds => Duration(seconds: this);
  Duration get milliseconds => Duration(milliseconds: this);
}

extension SizeConstraint on Size {
  Offset constraint(Offset pos) {
    late double dx, dy;
    if (pos.dx < 0) {
      dx = 0;
    } else if (pos.dx > width) {
      dx = width;
    } else {
      dx = pos.dx;
    }
    if (pos.dy < 0) {
      dy = 0;
    } else if (pos.dy > height) {
      dy = height;
    } else {
      dy = pos.dy;
    }
    return Offset(dx, dy);
  }
}

extension PecentExt on int {
  String percent(int max) => '${(this / max * 100).toStringAsFixed(0)}%';
}
