import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:painter/common/local_storage.dart';
import 'package:painter/page/draw/draw_data.dart';
import 'package:painter/page/draw/draw_painter.dart';

class LayerController with ChangeNotifier {
  /// 绘制的路径
  final List<LayerData> layers = [];

  /// 当前图层下表
  late int curLayerIndex;

  /// 背景颜色
  late Color bgColor;

  LayerData get curLayer => layers[curLayerIndex];

  LayerController() {
    bgColor = defaultBgColor;
    addLayer();
    curLayerIndex = 0;
  }

  /// 设置背景颜色
  setBgColor(Color color) {
    bgColor = color;
    notifyListeners();
  }

  setLayerVisible(int index, bool visible) {
    if (index < layers.length) {
      layers[index].setVisible(visible);
      print('notify');
      notifyListeners();
    }
  }

  orderLayer(int oldIndex, int newIndex) {
    if (oldIndex < layers.length && newIndex < layers.length) {
      final elem = layers.removeAt(oldIndex);
      layers.insert(newIndex, elem);
      notifyListeners();
    }
  }

  addLayer([String? name]) {
    var newLayer = LayerData();
    newLayer.addListener(_onEvent);
    layers.add(newLayer);
    notifyListeners();
  }

  setCurLayer(LayerData layer) {
    var idx = layers.indexOf(layer);
    if (idx != -1 && idx != curLayerIndex) {
      curLayerIndex = idx;
      notifyListeners();
    }
  }

  bool isCurLayer(LayerData layer) =>
    layer == curLayer;

  bool removeLayer(LayerData layer) {
    var index = layers.indexOf(layer);
    // 不允许空图层
    if (index != -1 && layers.length > 1) {
      // 移除的是当前图层
      if (curLayerIndex == index) {
        if (curLayerIndex != 0) {
          curLayerIndex -= 1;
        }
      }
      var layer = layers.removeAt(index);
      layer.removeListener(_onEvent);
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  void _onEvent() {
    notifyListeners();
  }

  void addLine(DrawEntity entity) {
    curLayer.addLine(entity);
    notifyListeners();
  }

  /// 清除绘制
  clear() {
    for (var layer in layers) {
      layer.clear();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
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

class TempPainterController with ChangeNotifier {
  final Paint brush;

  DrawEntity? curEntity;

  PaintMode mode;

  Color color;

  double strokeWidth;

  Color bgColor;

  bool get isEraserMode => mode == PaintMode.eraser;

  TempPainterController()
      : brush = Paint()
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke,
        bgColor = defaultBgColor,
        color = LocalStorage.lastRecentColor,
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

class LayerData with ChangeNotifier {
  /// 图层名字
  late String name;

  /// 图层key
  late UniqueKey key;

  /// 绘制的路径
  final List<DrawEntity> lines = [];

  /// 撤回的线条
  final List<DrawEntity> garbageLines = [];

  /// 笔刷
  late final Paint lineBrush;

  /// 是否可见
  bool visible = true;

  /// 透明度
  int opacity = 0xff;

  String get opacityPercent => '${(opacity / 0xff * 100).toStringAsFixed(0)}%';

  /// 是否可以撤销
  bool get canUndo => lines.isNotEmpty;

  /// 是否可以重做
  bool get canRedo => garbageLines.isNotEmpty;

  LayerData([String? layerName]) {
    lineBrush = Paint()
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    name = layerName ?? 'new Layer';
    key = UniqueKey();
  }

  void addLine(DrawEntity entity) {
    lines.add(entity);
    // 重新绘制之后 垃圾箱里的需要情况
    if (garbageLines.isNotEmpty) {
      garbageLines.clear();
    }
    notifyListeners();
  }

  undo() {
    if (lines.isNotEmpty) {
      var entity = lines.removeLast();
      garbageLines.add(entity);
      notifyListeners();
    }
  }

  redo() {
    if (garbageLines.isNotEmpty) {
      var entity = garbageLines.removeLast();
      addLine(entity);
    }
  }

  setVisible(bool isVisible) {
    if (visible != isVisible) {
      visible = isVisible;
      notifyListeners();
    }
  }

  setOpacity(int newOpacity) {
    if (opacity != newOpacity && newOpacity >= 0 && newOpacity <= 0xff) {
      opacity = newOpacity;
      notifyListeners();
    }
  }

  clear() {
    lines.clear();
    garbageLines.clear();
    notifyListeners();
  }
}
