import 'package:flutter/material.dart';
import 'package:painter/page/draw/draw_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 初始化并缓存一个全局的[SharedPreferences]实例方便同步调用
class LocalStorage {
  static late SharedPreferences _instance;

  static SharedPreferences get I => _instance;

  static Future<void> init() async {
    _instance = await SharedPreferences.getInstance();
    // _instance.clear();
  }

  static const recentColorKey = 'color';

  static void unShiftColor(Color color) {
    var list = getColorValue().toList();
    var val = color.value;
    var index = list.indexOf(val);
    if (index != -1) {
      list.removeAt(index);
      list.insert(0, val);
    } else {
      list.insert(0, val);
      if (list.length > 20) {
        list.removeRange(20, list.length);
      }
    }
    _instance.setString(recentColorKey, list.join(','));
  }

  static List<Color> getColors() {
    return getColorValue().map(Color.new).toList(growable: false);
  }

  static Iterable<int> getColorValue() {
    var str = _instance.getString(recentColorKey) ?? '';
    return str.split(',').where((element) => element.isNotEmpty)
        .map(int.parse);
  }

  static Color get lastRecentColor {
    var colors = getColorValue();
    if (colors.isEmpty) {
      return defaultColor;
    } else {
      return Color(colors.first);
    }
  }
}
