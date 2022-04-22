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
        bottomNavigationBar: buildBottomBar(),
        body: Stack(
          children: [
            Center(
              child: ColoredBox(
                color: Colors.white,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxHeight > constraints.maxWidth) {
                      paintSize = Size.square(constraints.maxWidth);
                    } else {
                      paintSize = Size.square(constraints.maxHeight);
                    }
                    return SizedBox.fromSize(
                      size: paintSize,
                      child: Stack(
                        children: [
                          /// 只显示旧线段
                          buildLayer(),
                          // 当前绘制线段
                          buildTemp(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            // buildZoom(),
          ],
        ),
      ),
    );
  }

  Selector<DrawPageModel, Tuple2<double, Offset>> buildTemp() {
    return Selector<DrawPageModel, Tuple2<double, Offset>>(
      selector: (context, m) => Tuple2(m.zoom, m._zoomOffset),
      builder: (context, val, child) => SizedBox.fromSize(
        size: paintSize,
        child: Transform.scale(
          scale: val.item1,
          origin: val.item2,
          child: Selector<DrawPageModel, bool>(
              selector: (_, __) => model.isZoom,
              child: RepaintBoundary(
                child: CustomPaint(
                  size: paintSize,
                  painter: TempDrawPainter(tempController),
                ),
              ),
              builder: (context, _, child) {
                if (model.isZoom) {
                  return GestureDetector(
                    onScaleStart: onZoomStart,
                    onScaleUpdate: onZoomUpdate,
                    onScaleEnd: onZoomEnd,
                    child: child,
                  );
                } else {
                  return GestureDetector(
                    onPanStart: onDrawStart,
                    onPanUpdate: onDrawUpdate,
                    onPanEnd: onDrawEnd,
                    child: child,
                  );
                }
              }),
        ),
      ),
    );
  }

  Selector<DrawPageModel, Tuple2<double, Offset>> buildLayer() {
    return Selector<DrawPageModel, Tuple2<double, Offset>>(
      selector: (_, __) {
        return Tuple2(model.zoom, model.zoomOrigin);
      },
      builder: (context, _, child) => Container(
        width: paintSize.width,
        height: paintSize.height,
        decoration: const BoxDecoration(color: Colors.blueGrey),
        clipBehavior: Clip.hardEdge,
        child: Transform.scale(
          scale: model.zoom,
          origin: model.zoomOrigin,
          child: child,
        ),
      ),
      child: RepaintBoundary(
        child: CustomPaint(
          size: paintSize,
          painter: DrawPainter(layerController),
        ),
      ),
    );
  }

  Material buildBottomBar() {
    return Material(
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
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(
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
                icon: Selector<DrawPageModel, bool>(
                  selector: (_, __) => model.isZoom,
                  builder: (_, isZoom, __) => Icon(
                    Icons.zoom_in,
                    color: isZoom ? Colors.blue : null,
                  ),
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
    );
  }

  void onDrawStart(DragStartDetails details) {
    tempController.newLine(details.localPosition);
  }

  void onDrawUpdate(DragUpdateDetails details) {
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
      onDrawEnd(null);
    }
  }

  void onDrawEnd(dynamic _) {
    var entity = tempController.lineDone();
    if (entity != null) {
      layerController.addLine(entity);
    }
  }

  void onZoomStart(ScaleStartDetails details) {
    model._initialFocalPoint = details.focalPoint;
    model._initialScale = model.zoom;
  }

  void onZoomUpdate(ScaleUpdateDetails details) {
    final sp = details.focalPoint - model._initialFocalPoint;
    model.setSessionZoomOffset(sp);
    model.setZoom(model._initialScale * details.scale);
  }

  void onZoomEnd(ScaleEndDetails details) {
    model.setZoomOffset(model._zoomOffset + model._sessionOffset);
    model.setSessionZoomOffset(Offset.zero);
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
    model.setIsZoom(!model.isZoom);
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
    await showModalBottomSheet(
      context: context,
      barrierColor: Colors.black12,
      builder: (context) {
        return SafeArea(
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
                          child: Text(opacityModel.obs(context).percent(0xff)),
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
      barrierColor: Colors.black12,
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
                          child: ReorderableListView.builder(
                            itemCount: layerController.layers.length,
                            itemExtent: itemExtend,
                            onReorder: (a, b) {
                              layerController.orderLayer(a, b);
                            },
                            itemBuilder: (context, index) {
                              final layer = layerController.layers[index];
                              return LayerItem(
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
                              );
                            },
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

  DrawPageModel() {
    resetZoom();
  }

  late double zoom;
  bool isZoom = false;
  bool get isDefaultZoom => zoom == defaultZoom;

  Offset _initialFocalPoint = Offset.zero;
  double _initialScale = 0;

  late Offset _zoomOffset;
  Offset _sessionOffset = Offset.zero;

  Offset get zoomOrigin => _zoomOffset + _sessionOffset;

  setZoom(double val) {
    if (val > maxZoom || val < minZoom) {
      return;
    }
    zoom = val;
    notifyListeners();
  }

  void resetZoom([bool? notify]) {
    zoom = defaultZoom;
    _zoomOffset = Offset.zero;
    if (notify == true) {
      notifyListeners();
    }
  }

  void setZoomOffset(Offset offset) {
    _zoomOffset = offset;
    notifyListeners();
  }

  void setSessionZoomOffset(Offset offset) {
    _sessionOffset = offset;
    notifyListeners();
  }

  void setIsZoom(bool _isZoom) {
    isZoom = _isZoom;
    if (!_isZoom) {
      resetZoom();
    }
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
                      showDialog(
                        context: context,
                        builder: (_) {
                          var name = layer.name;
                          return AlertDialog(
                            title: const Text('Edit Name'),
                            content: TextFormField(
                              onChanged: (val) => name = val,
                              initialValue: layer.name,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (name.isNotEmpty) {
                                    layer.setName(name);
                                  }
                                  Navigator.pop(context);
                                },
                                child: const Text('confirm'),
                              ),
                            ],
                          );
                        },
                      );
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
                              Material(
                                type: MaterialType.transparency,
                                child: IconButton(
                                  onPressed: () {
                                    layer.setVisible(!layer.visible);
                                  },
                                  icon: Icon(
                                    layer.visible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: onOpacity,
                                child: Row(
                                  children: [
                                    const Icon(Icons.opacity),
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
                              child: Selector<LayerData, String>(
                                selector: (_, __) => layer.name,
                                builder: (_, name, child) => Text(
                                  name,
                                ),
                              ),
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
