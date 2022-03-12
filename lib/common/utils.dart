import 'package:flutter/material.dart';

class SingleValueProvider<T> with ChangeNotifier {
  T _value;
  T get value => _value;
  set value(T val) {
    _value = val;
    notifyListeners();
  }
  SingleValueProvider(T value): _value = value;
}

extension IntObsExt on int {
  SingleValueProvider<int> get obs => SingleValueProvider(this);
}

extension DoubleObsExt on double {
  SingleValueProvider<double> get obs => SingleValueProvider(this);
}
