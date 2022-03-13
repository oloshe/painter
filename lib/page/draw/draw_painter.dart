import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:painter/page/draw/draw_data.dart';

class DrawPainter extends CustomPainter {
  final PainterController controller;
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
    PainterController _controller,
  ) {
    // 清除超过的部分
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = _controller.bgColor,
    );
    var _lines = _controller._lines;
    var _lineBrush = _controller._lineBrush;
    var len = _lines.length;
    for (var i = 0; i < len; i++) {
      var item = _lines[i];
      item.draw(canvas, _lineBrush, _controller.bgColor);
    }
  }

  @override
  bool shouldRepaint(DrawPainter oldDelegate) {
    return false;
  }
}

class PainterController extends ChangeNotifier {
  /// 绘制的路径
  late final List<DrawEntity> _lines;

  /// 撤回的线条
  late final List<DrawEntity> _garbageLines;

  late final Paint _lineBrush;

  /// 背景颜色
  Color bgColor;

  bool get canUndo => _lines.isNotEmpty;

  bool get canRedo => _garbageLines.isNotEmpty;

  PainterController()
      : _lineBrush = Paint()
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke,
        bgColor = defaultBgColor,
        _garbageLines = [],
        _lines = [];

  void addLine(DrawEntity entity) {
    _lines.add(entity);
    // 重新绘制之后 垃圾箱里的需要情况
    if (_garbageLines.isNotEmpty) {
      _garbageLines.clear();
    }
    notifyListeners();
  }

  /// 设置背景颜色
  setBgColor(Color color) {
    bgColor = color;
    notifyListeners();
  }

  /// 清除绘制
  clear() {
    _lines.clear();
    _garbageLines.clear();
    notifyListeners();
  }

  undo() {
    if (_lines.isNotEmpty) {
      var entity = _lines.removeLast();
      _garbageLines.add(entity);
      notifyListeners();
    }
  }

  redo() {
    if (_garbageLines.isNotEmpty) {
      var entity = _garbageLines.removeLast();
      addLine(entity);
    }
  }

  /// 获取绘制的图片
  Future<ByteData> getImage(Size canvasSize) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
    );
    DrawPainter.paintWith(canvas, canvasSize, this);
    final picture = recorder.endRecording();
    final img = await picture.toImage(
      canvasSize.width.toInt(),
      canvasSize.height.toInt(),
    );
    var byteData = await img.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!;
  }
}

/// 当前绘制的
class TempDrawPainter extends CustomPainter {
  final TempPainterController controller;
  TempDrawPainter(this.controller) : super(repaint: controller);

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    controller.curEntity?.draw(canvas, controller._brush, controller.bgColor);
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

class TempPainterController with ChangeNotifier {
  final Paint _brush;

  DrawEntity? curEntity;

  PaintMode mode;

  Color color;

  double strokeWidth;

  Color bgColor;

  bool get isEraserMode => mode == PaintMode.eraser;

  TempPainterController()
      : _brush = Paint()
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke,
        bgColor = defaultBgColor,
        color = Colors.black,
        mode = PaintMode.pen,
        strokeWidth = 3.0;

  /// 新增一条线
  void newLine(Offset from) {
    curEntity = DrawEntity(
      from,
      color: color,
      strokeWidth: strokeWidth,
      clear: mode == PaintMode.eraser,
    );
  }

  /// 笔画位置更新
  bool lineTo(Offset next) {
    var haveCur = curEntity != null;
    if (haveCur) {
      curEntity!.to(next);
      notifyListeners();
    }
    return haveCur;
  }

  /// 完成一个笔画
  DrawEntity? lineDone() {
    if (curEntity != null) {
      var entity = curEntity!;
      curEntity = null;
      notifyListeners();
      return entity;
    } else {
      return null;
    }
  }

  /// 设置宽度
  setStrokeWidth(double width) {
    strokeWidth = width;
  }

  /// 设置颜色
  setColor(Color newColor) {
    color = newColor;
    notifyListeners();
  }

  setBgColor(Color color) {
    bgColor = color;
  }

  setMode(PaintMode newMode) {
    mode = newMode;
    notifyListeners();
  }
}
