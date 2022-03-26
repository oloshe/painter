import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:painter/common/local_storage.dart';
import 'package:painter/page/draw/draw_data.dart';
import 'package:painter/page/draw/draw_model.dart';

class DrawPainter extends CustomPainter {
  final LayerController controller;
  final double? scale;

  DrawPainter(
    this.controller, {
    this.scale,
  }) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    var t = DateTime.now().millisecondsSinceEpoch;
    if (scale != null) {
      canvas.scale(scale!);
    }
    paintWith(canvas, size, controller);
    // print(DateTime.now().millisecondsSinceEpoch - t);
  }

  static void paintWith(
    Canvas canvas,
    Size size,
    LayerController _controller,
  ) {
    // 清除超过的部分
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = _controller.bgColor,
    );
    for (var layer in _controller.layers) {
      if (!layer.visible) {
        continue;
      }
      var _lines = layer.lines;
      var _lineBrush = layer.lineBrush;
      var len = _lines.length;
      for (var i = 0; i < len; i++) {
        var item = _lines[i];
        item.draw(
          canvas,
          _lineBrush,
          _controller.bgColor,
          layer.opacity,
        );
      }
    }
  }

  @override
  bool shouldRepaint(DrawPainter oldDelegate) {
    return false;
  }
}

/// 当前绘制的
class TempDrawPainter extends CustomPainter {
  final TempPainterController controller;
  TempDrawPainter(this.controller) : super(repaint: controller);

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    controller.curEntity?.draw(canvas, controller.brush, controller.bgColor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

enum PaintMode {
  pen,
  eraser,
}
