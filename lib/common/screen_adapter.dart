import 'package:flutter/material.dart';

/// 类似小程序的rpx适配方式，不管什么屏幕，始终认为宽度是750rpx
class ScreenAdaptor {
  static late MediaQueryData _mediaQueryData;
  static late double _screenWidth;
  static late double _screenHeight;
  static late double _scale;

  static late double _notchHeight;

  static late double _notchBottom;

  /// 根据获取的实际screenWidth和screenHeight计算出1个rpx对应的实际长度
  /// [designedWidth]是设计稿的标准宽度，默认750
  static void init(BuildContext context, {double designedWidth = 750}) {
    _mediaQueryData = MediaQuery.of(context);
    _screenWidth = _mediaQueryData.size.width;
    _screenHeight = _mediaQueryData.size.height;
    _scale = _screenWidth / designedWidth;
    _notchHeight = _mediaQueryData.padding.top;
    _notchBottom = _mediaQueryData.padding.bottom;
  }

  /// 缩放因子，小于1
  static double get scale => _scale;

  /// 屏幕宽的dp值
  static double get screenWidth => _screenWidth;

  /// 屏幕高的dp值
  static double get screenHeight => _screenHeight;

  /// 顶部刘海高度
  static double get notchHeight => _notchHeight;

  static double get notchBottom => _notchBottom;

  /// 把rpx值转换为flutter实际使用的dp值
  static double rpx2dp(double rpx) {
    return _scale * rpx;
  }

  /// 把dp值转换为rpx值
  static double dp2rpx(double dp) {
    return dp / _scale;
  }
}

///  为int类型扩展.rpx方法
extension IntFit on int {
  /// 把设计稿尺寸转换成实际用于显示的dp值
  double get rpx {
    return ScreenAdaptor.rpx2dp(toDouble());
  }

  /// 把实际获取到的dp值转换成按设计稿缩放过的rpx数值
  double get toRpx {
    return ScreenAdaptor.dp2rpx(toDouble());
  }
}

///  为double类型扩展.rpx方法
extension DoubleFit on double {
  /// 把设计稿尺寸转换成实际用于显示的dp值
  double get rpx {
    return ScreenAdaptor.rpx2dp(this);
  }

  /// 把实际获取到的dp值转换成按设计稿缩放过的rpx数值
  double get toRpx {
    return ScreenAdaptor.dp2rpx(this);
  }
}

/// 为Offset类型扩展.rpx方法
extension OffsetFit on Offset {
  /// 把设计稿尺寸转换成实际用于显示的dp值
  Offset get rpx {
    return Offset(
      ScreenAdaptor.rpx2dp(dx),
      ScreenAdaptor.rpx2dp(dy),
    );
  }

  /// 把实际获取到的dp值转换成按设计稿缩放过的rpx数值
  Offset get toRpx {
    return Offset(
      ScreenAdaptor.dp2rpx(dx),
      ScreenAdaptor.dp2rpx(dy),
    );
  }
}

/// 为Size类型扩展.rpx方法
extension SizeFit on Size {
  /// 把设计稿尺寸转换成实际用于显示的dp值
  Size get rpx {
    return Size(
      ScreenAdaptor.rpx2dp(width),
      ScreenAdaptor.rpx2dp(height),
    );
  }

  /// 把实际获取到的dp值转换成按设计稿缩放过的rpx数值
  Size get toRpx {
    return Size(
      ScreenAdaptor.dp2rpx(width),
      ScreenAdaptor.dp2rpx(height),
    );
  }
}
