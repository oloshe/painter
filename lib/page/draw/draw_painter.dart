import 'package:flutter/material.dart';
import 'package:painter/page/draw/draw_data.dart';

class DrawPainter extends CustomPainter {
  final PainterController controller;

  DrawPainter(this.controller) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    print('paint!');
    var _lines = controller._lines;
    var _lineBrush = controller._lineBrush;

    var len = _lines.length;
    for (var i = 0; i < len; i++) {
      var item = _lines[i];
      _lineBrush
        ..color = item.color
        ..strokeWidth = item.strokeWidth;

      item.offset.reduce((p, n) {
        canvas.drawLine(p, n, _lineBrush);
        return n;
      });
    }
  }

  @override
  bool shouldRepaint(DrawPainter oldDelegate) {
    return false;
  }
}

class PainterController extends ChangeNotifier {
  late final List<DrawEntity> _lines;

  late final Paint _lineBrush;

  Color color;

  double strokeWidth;

  DrawEntity? curEntity;

  PainterController()
      : _lineBrush = Paint()
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke,
        _lines = [],
        color = Colors.black,
        strokeWidth = 3.0;

  void newLine(Offset from) {
    curEntity = DrawEntity(from, color: color, strokeWidth: strokeWidth);
    _lines.add(curEntity!);
  }

  void lineTo(Offset next) {
    if (curEntity != null) {
      curEntity!.to(next);
      notifyListeners();
    }
  }

  lineDone() => curEntity = null;

  setColor(Color newColor) {
    color = newColor;
    notifyListeners();
  }

  setStrokeWidth(double width) {
    strokeWidth = width;
  }

  clear() {
    _lines.clear();
    notifyListeners();
  }
}
