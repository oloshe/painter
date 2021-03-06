import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:painter/common/local_storage.dart';
import 'package:painter/dep.dart';
import 'package:painter/page/draw/draw_page.dart';

void main() {
  // 加载字体许可
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: Builder(builder: (context) {
        ScreenAdaptor.init(context);
        return FutureBuilder(
          future: Future.wait([
            LocalStorage.init(),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return const DrawPage();
            } else {
              return const SizedBox.shrink();
            }
          },
        );
      }),
    );
  }
}
