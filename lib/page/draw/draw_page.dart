import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
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
  late final Size paintSize;

  @override
  void initState() {
    super.initState();
    paintSize = Size(400, 400);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(
            "Test fonts GIAO!!",
            style: GoogleFonts.lobster(
              fontSize: 40.rpx,
            ),
          ),
        ),
        bottomNavigationBar: Material(
          elevation: 20,
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: Row(
              children: [
                Selector<PainterController, Color>(
                  selector: (context, val) => val.color,
                  builder: (context, val, child) => ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(val),
                      padding: MaterialStateProperty.all(EdgeInsets.zero),
                      shape: MaterialStateProperty.all(const CircleBorder()),
                    ),
                    onPressed: showColorPicker,
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: showColorPicker,
                  icon: const Icon(
                    Icons.color_lens_rounded,
                  ),
                ),
                IconButton(
                  onPressed: showSizeSelector,
                  icon: const Icon(
                    Icons.brush_rounded,
                  ),
                ),
                IconButton(
                  onPressed: controller.clear,
                  icon: const Icon(Icons.cleaning_services_outlined),
                )
              ],
            ),
          ),
        ),
        backgroundColor: Colors.grey,
        body: Center(
          child: ColoredBox(
            color: Colors.white,
            child: SizedBox.fromSize(
              size: paintSize,
              child: SingleTouchWidget(
                child: GestureDetector(
                  onPanStart: (details) {
                    controller.newLine(details.localPosition);
                  },
                  onPanUpdate: (details) {
                    controller.lineTo(details.localPosition);
                  },
                  onPanEnd: (details) {
                    controller.lineDone();
                  },
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: Size(ScreenAdaptor.screenWidth, double.infinity),
                      painter: DrawPainter(controller),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showColorPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: ColorPicker(
          colorPickerWidth: ScreenAdaptor.screenWidth,
          pickerColor: controller.color,
          enableAlpha: false,
          onColorChanged: (c) {
            controller.setColor(c);
          },
        ),
      ),
    );
  }

  void showSizeSelector() async {
    var model = controller.strokeWidth.obs;
    var _res = await showModalBottomSheet(
      context: context,
      builder: (context) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: model),
          ],
          builder: (context, _) {
            return Column(
              children: [
                Slider(
                  min: 1,
                  max: 100,
                  value:
                      Provider.of<SingleValueProvider<double>>(context).value,
                  onChanged: (val) {
                    model.value = val;
                  },
                )
              ],
            );
          },
        );
      },
    );
    controller.setStrokeWidth(model.value);
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
