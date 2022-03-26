import 'dart:ffi';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:painter/common/extension.dart';
import 'package:painter/common/local_storage.dart';
import 'package:painter/common/utils.dart';
import 'package:painter/dep.dart';
import 'package:painter/page/draw/draw_data.dart';
import 'package:painter/page/draw/draw_model.dart';
import 'package:painter/page/draw/draw_painter.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

class DrawPage extends StatefulWidget {
  const DrawPage({Key? key}) : super(key: key);

  @override
  State<DrawPage> createState() => _DrawPageState();
}

class _DrawPageState extends State<DrawPage> {
  final LayerController layerController = LayerController();
  final TempPainterController tempController = TempPainterController();
  final DrawPageModel model = DrawPageModel();
  late Size paintSize;
  final GlobalKey paintKey = GlobalKey();
  final int _throttleMillsSecond = 15;
  int _lastMillsSecond = 0;

  @override
  void initState() {
    super.initState();
    // paintSize = Size(400.rpx, 400.rpx);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: layerController),
        ChangeNotifierProvider.value(value: tempController),
        ChangeNotifierProvider.value(value: model),
      ],
      builder: (context, _) => Scaffold(
        backgroundColor: Colors.grey,
        appBar: AppBar(
          title: Text(
            "Painter",
            style: GoogleFonts.lobster(
              fontSize: 40,
            ),
          ),
          actions: [
            Selector<LayerController, bool>(
              selector: (context, controller) => controller.curLayer.canUndo,
              builder: (context, can, child) => IconButton(
                onPressed: can ? layerController.curLayer.undo : null,
                icon: const Icon(Icons.undo),
              ),
            ),
            Selector<LayerController, bool>(
              selector: (context, controller) => controller.curLayer.canRedo,
              builder: (context, can, child) => IconButton(
                onPressed: can ? layerController.curLayer.redo : null,
                icon: const Icon(Icons.redo),
              ),
            ),
            IconButton(
              onPressed: onSaveImage,
              icon: const Icon(Icons.save_rounded),
            ),
          ],
        ),
        bottomNavigationBar: Material(
          elevation: 20,
          child: SizedBox(
            height: 60,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    height: double.infinity,
                    child: Selector<TempPainterController, Color>(
                      selector: (context, val) => val.color,
                      builder: (context, val, child) => ElevatedButton(
                        onPressed: showBrushColorPicker,
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(val),
                            shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.elliptical(60, 100),
                                    ),
                                    side: BorderSide(color: val)))),
                        child: const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: showRecentColorPicker,
                    icon: const Icon(
                      Icons.color_lens_rounded,
                    ),
                  ),
                  IconButton(
                    onPressed: showBackgroundColorPicker,
                    icon: const Icon(
                      Icons.image,
                    ),
                  ),
                  IconButton(
                    onPressed: showSizeSelector,
                    icon: const Icon(
                      Icons.brush_rounded,
                    ),
                  ),
                  Selector<TempPainterController, PaintMode>(
                    selector: (context, c) => c.mode,
                    builder: (context, val, child) => IconButton(
                      onPressed: onSetEraserMode,
                      icon: Icon(
                        Icons.format_color_reset,
                        color: val == PaintMode.eraser ? Colors.blue : null,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: showLayerSetting,
                    icon: const Icon(
                      Icons.layers,
                    ),
                  ),
                  IconButton(
                    onPressed: onShowZoom,
                    icon: const Icon(
                      Icons.zoom_out_map_rounded,
                    ),
                  ),
                  IconButton(
                    onPressed: _onClear,
                    icon: const Icon(Icons.clear_rounded),
                  )
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            Center(
              child: ColoredBox(
                color: Colors.white,
                child: LayoutBuilder(builder: (context, constraints) {
                  if (constraints.maxHeight > constraints.maxWidth) {
                    paintSize = Size.square(constraints.maxWidth * 0.8);
                  } else {
                    paintSize = Size.square(constraints.maxHeight);
                  }
                  return SizedBox.fromSize(
                    size: paintSize,
                    child: Stack(
                      children: [
                        /// 只显示旧线段
                        Selector<DrawPageModel, Tuple2<double, Offset>>(
                          selector: (context, m) {
                            return Tuple2(m.zoom, m.zoomOffset);
                          },
                          builder: (context, val, child) => Container(
                            width: paintSize.width,
                            height: paintSize.height,
                            decoration: const BoxDecoration(),
                            clipBehavior: Clip.hardEdge,
                            child: Transform.scale(
                              scale: val.item1,
                              origin: val.item2,
                              child: child,
                            ),
                          ),
                          child: RepaintBoundary(
                            child: CustomPaint(
                              size: paintSize,
                              painter: DrawPainter(layerController),
                            ),
                          ),
                        ),
                        // 当前绘制线段
                        Selector<DrawPageModel, Tuple2<double, Offset>>(
                          selector: (context, m) =>
                              Tuple2(m.zoom, m.zoomOffset),
                          builder: (context, val, child) => SizedBox.fromSize(
                            size: paintSize,
                            child: SingleTouchWidget(
                              child: Transform.scale(
                                scale: val.item1,
                                origin: val.item2,
                                child: GestureDetector(
                                  onPanStart: onDown,
                                  onPanUpdate: onUpdate,
                                  onPanEnd: (_) => onEnd(),
                                  child: RepaintBoundary(
                                    child: CustomPaint(
                                      size: paintSize,
                                      painter: TempDrawPainter(tempController),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: Selector<DrawPageModel, bool>(
                selector: (context, m) => m.isDefaultZoom,
                builder: (context, hidden, child) {
                  if (hidden) {
                    return const SizedBox.shrink();
                  }
                  return LayoutBuilder(builder: (context, _) {
                    return Selector<DrawPageModel, bool>(
                        selector: (_, m) => m.zoomMoving,
                        builder: (context, val, child) {
                          return AnimatedOpacity(
                            opacity: val ? 1 : 0.4,
                            duration: 500.milliseconds,
                            child: Transform.scale(
                              scale: 0.4,
                              alignment: Alignment.topLeft,
                              child: GestureDetector(
                                onPanDown: (details) {
                                  model.setZoomOffset(
                                      paintSize, details.localPosition);
                                  model.setZoomMoving(true);
                                },
                                onPanUpdate: (details) {
                                  model.setZoomOffset(
                                      paintSize, details.localPosition);
                                },
                                onPanEnd: (details) {
                                  model.setZoomMoving(false);
                                },
                                onPanCancel: () {
                                  model.setZoomMoving(false);
                                },
                                onDoubleTap: () {
                                  model.resetZoom(true);
                                },
                                child: Container(
                                  width: paintSize.width,
                                  height: paintSize.height,
                                  decoration: const BoxDecoration(
                                      color: Colors.black26,
                                      border: Border.fromBorderSide(
                                        BorderSide(color: Colors.blue),
                                      )),
                                  child: Center(
                                    child: RepaintBoundary(
                                      child: CustomPaint(
                                        size: paintSize,
                                        painter: DrawPainter(layerController,
                                            scale: 1),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        });
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onDown(DragStartDetails details) {
    tempController.newLine(details.localPosition);
  }

  void onUpdate(DragUpdateDetails details) {
    // var now = DateTime.now().millisecondsSinceEpoch;
    // if (now - _lastMillsSecond < _throttleMillsSecond) {
    //   return;
    // }
    // _lastMillsSecond = now;
    var pos = details.localPosition;
    // 在里面
    if (paintSize.contains(pos)) {
      var drew = tempController.lineTo(details.localPosition);
      if (!drew) {
        tempController.newLine(pos);
      }
    } else {
      onEnd();
    }
  }

  void onEnd() {
    var entity = tempController.lineDone();
    if (entity != null) {
      layerController.addLine(entity);
    }
  }

  // 弹出颜色选择
  void showBrushColorPicker() async {
    Color? tmpColor;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: ColorPicker(
          colorPickerWidth: ScreenAdaptor.screenWidth,
          pickerColor: tempController.color,
          enableAlpha: false,
          pickerAreaHeightPercent: 1 / 2,
          onColorChanged: (c) {
            tmpColor = c;
          },
        ),
      ),
    );
    if (tmpColor != null) {
      tempController.setColor(tmpColor!);
      LocalStorage.unShiftColor(tmpColor!);
    }
  }

  /// 调色板 最近颜色
  void showRecentColorPicker() {
    var colors = LocalStorage.getColors();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20.rpx,
            right: 19.rpx,
            top: 10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Default', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 10),
              BlockPicker(
                pickerColor: tempController.color,
                availableColors: defaultColors,
                onColorChanged: (c) {
                  tempController.setColor(c);
                },
                layoutBuilder: (context, list, child) {
                  return Wrap(
                    spacing: 22.rpx,
                    runSpacing: 14.rpx,
                    children: list
                        .map((e) => SizedBox.square(
                              dimension: 80.rpx,
                              child: child(e),
                            ))
                        .toList(growable: false),
                  );
                },
                itemBuilder: (c, isCurr, onChange) {
                  return ElevatedButton(
                    onPressed: onChange,
                    child: isCurr
                        ? const Icon(
                            Icons.done,
                            size: 15,
                          )
                        : const SizedBox.shrink(),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(c),
                      elevation: isCurr ? MaterialStateProperty.all(10) : null,
                      shadowColor: isCurr
                          ? MaterialStateProperty.all(Colors.yellow)
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              const Text('Recent', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 10),
              BlockPicker(
                pickerColor: tempController.color,
                availableColors: colors,
                onColorChanged: (c) {
                  tempController.setColor(c);
                  LocalStorage.unShiftColor(c);
                },
                layoutBuilder: (context, list, child) {
                  return Wrap(
                    spacing: 22.rpx,
                    runSpacing: 14.rpx,
                    children: list
                        .map((e) => SizedBox.square(
                              dimension: 80.rpx,
                              child: child(e),
                            ))
                        .toList(growable: false),
                  );
                },
                itemBuilder: (c, isCurr, onChange) {
                  return ElevatedButton(
                    onPressed: onChange,
                    child: isCurr
                        ? const Icon(
                            Icons.done,
                            size: 15,
                          )
                        : const SizedBox.shrink(),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(c),
                      elevation: isCurr ? MaterialStateProperty.all(10) : null,
                      shadowColor: isCurr
                          ? MaterialStateProperty.all(Colors.yellow)
                          : null,
                    ),
                  );
                },
              ),
              SizedBox(
                height: ScreenAdaptor.notchBottom + 50.rpx,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 背景颜色选择
  void showBackgroundColorPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: BlockPicker(
          pickerColor: layerController.bgColor,
          availableColors: defaultColors,
          onColorChanged: (c) {
            layerController.setBgColor(c);
            tempController.setBgColor(c);
          },
          layoutBuilder: (context, list, child) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20.rpx,
                right: 19.rpx,
                bottom: ScreenAdaptor.notchBottom + 50.rpx,
              ),
              child: Wrap(
                spacing: 22.rpx,
                runSpacing: 10.rpx,
                children: list
                    .map((e) => SizedBox.square(
                          dimension: 100.rpx,
                          child: child(e),
                        ))
                    .toList(growable: false),
              ),
            );
          },
          itemBuilder: (c, isCurr, onChange) {
            return ElevatedButton(
              onPressed: onChange,
              child: isCurr
                  ? const Icon(
                      Icons.done,
                      size: 15,
                    )
                  : const SizedBox.shrink(),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(c),
                elevation: isCurr ? MaterialStateProperty.all(10) : null,
                shadowColor:
                    isCurr ? MaterialStateProperty.all(Colors.yellow) : null,
                shape: MaterialStateProperty.all(
                  const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 弹出笔粗细选择
  void showSizeSelector() async {
    var widthModel = tempController.strokeWidth.provider;
    await showModalBottomSheet(
      context: context,
      elevation: 20,
      isScrollControlled: true,
      builder: (context) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: widthModel),
          ],
          builder: (context, _) {
            return SizedBox(
              height: 200.rpx + ScreenAdaptor.notchBottom,
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 300.rpx,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: tempController.color,
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox.square(
                              dimension: widthModel.value,
                            ),
                          ),
                        ),
                        Flexible(
                          flex: 1,
                          child: Slider(
                            min: minStroke,
                            max: maxStroke,
                            value: widthModel.obs(context),
                            onChanged: (val) {
                              widthModel.value = val;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: ScreenAdaptor.notchBottom,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    tempController.setStrokeWidth(widthModel.value);
  }

  /// 设置橡皮擦模式
  void onSetEraserMode() {
    switch (tempController.mode) {
      case PaintMode.pen:
        tempController.setMode(PaintMode.eraser);
        break;
      case PaintMode.eraser:
        tempController.setMode(PaintMode.pen);
        break;
      default:
        break;
    }
  }

  /// 显示缩放面板
  onShowZoom() {
    showModalBottomSheet(
      context: context,
      elevation: 20,
      isScrollControlled: true,
      builder: (context) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: model),
          ],
          builder: (context, _) {
            return SizedBox(
              height: 200.rpx + ScreenAdaptor.notchBottom,
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 100.rpx,
                          child: Center(
                            child: Selector<DrawPageModel, double>(
                              selector: (context, m) => m.zoom,
                              builder: (context, val, child) =>
                                  Text(val.toStringAsFixed(1)),
                            ),
                          ),
                        ),
                        Flexible(
                          flex: 1,
                          child: Selector<DrawPageModel, double>(
                            selector: (context, m) => m.zoom,
                            builder: (context, val, child) => Slider(
                              min: DrawPageModel.minZoom,
                              max: DrawPageModel.maxZoom,
                              value: val,
                              onChanged: (val) {
                                model.setZoom(val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: ScreenAdaptor.notchBottom,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onClear() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear'),
        content: Text('Are you sure to clear? It can\'t undo.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              layerController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void showSetOpacity(LayerData layer) async {
    var opacityModel = layer.opacity.provider;
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChangeNotifierProvider.value(
                value: opacityModel,
                builder: (context, child) {
                  return Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Center(
                          child: Text(opacityModel.obs(context).toString()),
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: opacityModel.obs(context).toDouble(),
                          min: 0,
                          max: 0xff,
                          onChanged: (double value) {
                            opacityModel.value = value.toInt();
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
    layer.setOpacity(opacityModel.value);
  }

  void showLayerSetting() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: ScreenAdaptor.screenHeight / 3,
          child: Column(
            children: [
              ColoredBox(
                color: Colors.white54,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        layerController.addLayer();
                      },
                      child: Row(
                        children: const [
                          Icon(Icons.add),
                          Text('Add Layer'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ChangeNotifierProvider.value(
                  value: layerController,
                  builder: (context, _) {
                    return Selector<LayerController, Tuple2<int, int>>(
                        selector: (_, __) {
                      return Tuple2(
                        layerController.layers.length,
                        layerController.curLayerIndex,
                      );
                    }, builder: (context, val, child) {
                      var itemExtend = 80.0;
                      return Expanded(
                        child: Scrollbar(
                          child: ListView(
                            itemExtent: itemExtend,
                            children: [
                              for (var layer in layerController.layers)
                                LayerItem(
                                  layer,
                                  key: layer.key,
                                  itemExtend: itemExtend,
                                  selected: layerController.isCurLayer(layer),
                                  onDelete: () {
                                    final ret =
                                        layerController.removeLayer(layer);
                                    if (!ret) {
                                      Fluttertoast.showToast(
                                        msg: "At least one layer",
                                        textColor: Colors.white,
                                      );
                                    }
                                  },
                                  onOpacity: () {
                                    showSetOpacity(layer);
                                  },
                                  onSelect: () {
                                    layerController.setCurLayer(layer);
                                  },
                                ),
                            ],
                          ),
                        ),
                      );
                    });
                  }),
            ],
          ),
        );
      },
    );
  }

  void onSaveImage() async {
    final byteData = await layerController.getImage(paintSize);
    ImageGallerySaver.saveImage(
      byteData.buffer.asUint8List(),
      quality: 100,
    );
  }
}

class DrawPageModel with ChangeNotifier {
  static double maxZoom = 5;
  static double minZoom = 1;
  static double defaultZoom = 1;
  late double zoom;
  late Offset zoomOffset;
  bool zoomMoving = false;

  bool get isDefaultZoom => zoom == defaultZoom;

  DrawPageModel() {
    resetZoom();
  }

  setZoom(double val) {
    if (val > maxZoom || val < minZoom) {
      return;
    }
    zoom = val;
    notifyListeners();
  }

  void resetZoom([bool? notify]) {
    zoom = defaultZoom;
    zoomOffset = const Offset(0, 0);
    if (notify == true) {
      notifyListeners();
    }
  }

  void setZoomOffset(Size origin, Offset pos) {
    var _pos = origin.constraint(pos);
    final halfX = origin.width / 2;
    final halfY = origin.height / 2;
    zoomOffset = _pos.translate(-halfX, -halfY);
    notifyListeners();
  }

  void setZoomMoving(bool moving) {
    zoomMoving = moving;
    notifyListeners();
  }
}

class LayerItem extends StatelessWidget {
  final LayerData layer;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback onOpacity;
  final double itemExtend;
  const LayerItem(
    this.layer, {
    required this.itemExtend,
    required this.selected,
    required this.onDelete,
    required this.onOpacity,
    required this.onSelect,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: layer,
      builder: (context, child) {
        return Consumer<LayerData>(
          builder: (context, data, child) {
            return Slidable(
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (_) {
                      // pass
                    },
                    icon: Icons.edit,
                    label: 'Rename',
                    spacing: 10,
                    backgroundColor: Colors.blueGrey,
                  ),
                  SlidableAction(
                    onPressed: (_) {
                      onDelete.call();
                    },
                    label: 'Delete',
                    icon: Icons.delete,
                    spacing: 10,
                    backgroundColor: Colors.red,
                  ),
                ],
              ),
              child: InkWell(
                onTap: onSelect,
                child: SizedBox(
                  height: itemExtend,
                  child: ColoredBox(
                    color: selected ? Colors.blue[100]! : Colors.white,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 40,
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  layer.setVisible(!layer.visible);
                                },
                                icon: Icon(
                                  layer.visible ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                              ),
                              TextButton(
                                onPressed: !layer.visible ? null : onOpacity,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.opacity,
                                      color:
                                          layer.visible ? Colors.blue : Colors.grey,
                                    ),
                                    Text(layer.opacityPercent),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(layer.name),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Divider(
                          height: 1,
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SingleTouchRecognizer extends OneSequenceGestureRecognizer {
  int _p = 0;

  @override
  void addPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer);

    if (_p == 0) {
      resolve(GestureDisposition.rejected);
      _p = event.pointer;
    } else {
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  String get debugDescription => 'single touch recognizer';

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  void handleEvent(PointerEvent event) {
    if (!event.down && event.pointer == _p) {
      _p = 0;
    }
  }
}

class SingleTouchWidget extends StatelessWidget {
  final Widget child;
  const SingleTouchWidget({
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        _SingleTouchRecognizer:
            GestureRecognizerFactoryWithHandlers<_SingleTouchRecognizer>(
          () => _SingleTouchRecognizer(),
          (_SingleTouchRecognizer instance) {},
        ),
      },
      child: child,
    );
  }
}
