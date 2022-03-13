import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:painter/common/utils.dart';
import 'package:painter/dep.dart';
import 'package:painter/page/draw/draw_data.dart';
import 'package:painter/page/draw/draw_painter.dart';
import 'package:provider/provider.dart';

class DrawPage extends StatefulWidget {
  const DrawPage({Key? key}) : super(key: key);

  @override
  State<DrawPage> createState() => _DrawPageState();
}

class _DrawPageState extends State<DrawPage> {
  final PainterController controller = PainterController();
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
        ChangeNotifierProvider.value(value: controller),
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
            Selector<PainterController, bool>(
              selector: (context, controller) => controller.canUndo,
              builder: (context, val, child) => IconButton(
                onPressed: controller.canUndo ? controller.undo : null,
                icon: const Icon(Icons.undo),
              ),
            ),
            Selector<PainterController, bool>(
              selector: (context, controller) => controller.canRedo,
              builder: (context, val, child) => IconButton(
                onPressed: controller.canRedo ? controller.redo : null,
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
                    onPressed: showBrushColorPicker,
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
                    onPressed: onShowZoom,
                    icon: const Icon(
                      Icons.zoom_out_map_rounded,
                    ),
                  ),
                  IconButton(
                    onPressed: controller.clear,
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
                  var oneSize =
                      min(constraints.maxHeight, constraints.maxWidth);
                  paintSize = Size.square(oneSize);
                  return SizedBox.fromSize(
                    size: paintSize,
                    child: Stack(
                      children: [
                        Selector<DrawPageModel, double>(
                          selector: (context, m) => m.zoom,
                          builder: (context, val, child) => Transform.scale(
                            scale: val,
                            origin: Offset.zero,
                            alignment: Alignment.topLeft,
                            child: child,
                          ),
                          child: RepaintBoundary(
                            child: CustomPaint(
                              size: paintSize,
                              painter: DrawPainter(controller),
                            ),
                          ),
                        ),
                        Selector<DrawPageModel, double>(
                          selector: (context, m) => m.zoom,
                          builder: (context, val, child) => Transform.scale(
                            scale: val,
                            origin: Offset.zero,
                            alignment: Alignment.topLeft,
                            child: child,
                          ),
                          child: SingleTouchWidget(
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
                      ],
                    ),
                  );
                }),
              ),
            ),
            // Positioned(
            //   top: 0,
            //   left: 0,
            //   child: Container(
            //     width: 200,
            //     height: 200,
            //     color: Colors.black26,
            //     child: LayoutBuilder(
            //       builder: (context, cons) {
            //         return RepaintBoundary(
            //           child: CustomPaint(
            //             size: paintSize,
            //             painter: DrawPainter(controller, scale: 0.5),
            //           ),
            //         );
            //       }
            //     ),
            //   ),
            // ),
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
      controller.addLine(entity);
    }
  }

  // 弹出颜色选择
  void showBrushColorPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: ColorPicker(
          colorPickerWidth: ScreenAdaptor.screenWidth,
          pickerColor: tempController.color,
          enableAlpha: false,
          pickerAreaHeightPercent: 1 / 2,
          onColorChanged: (c) {
            tempController.setColor(c);
          },
        ),
      ),
    );
  }

  void showBackgroundColorPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: BlockPicker(
          pickerColor: controller.bgColor,
          availableColors: defaultColors,
          onColorChanged: (c) {
            controller.setBgColor(c);
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
    var widthModel = tempController.strokeWidth.obs;
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
                            value: Provider.of<SingleValueProvider<double>>(
                              context,
                            ).value,
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

  onSetEraserMode() {
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
                            child: Text(DrawPageModel.of(context, true).zoom.toStringAsFixed(1)),
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

  void onSaveImage() async {
    final byteData = await controller.getImage(paintSize);
    ImageGallerySaver.saveImage(
      byteData.buffer.asUint8List(),
      quality: 100,
    );
  }
}

class DrawPageModel with ChangeNotifier {
  double zoom = 1;
  static double maxZoom = 5;
  static double minZoom = 1;

  static DrawPageModel of(BuildContext context, [bool listen = false]) =>
      Provider.of(context, listen: listen);

  setZoom(double val) {
    if (val > maxZoom || val < minZoom) {
      return;
    }
    zoom = val;
    notifyListeners();
  }

  addZoom() {
    setZoom(zoom + 0.1);
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
