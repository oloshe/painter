import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SingleValueProvider<T> with ChangeNotifier {
  T _value;
  T get value => _value;
  set value(T val) {
    _value = val;
    notifyListeners();
  }
  T obs(BuildContext context) =>
      Provider.of<SingleValueProvider<T>>(context).value;
  SingleValueProvider(T value): _value = value;
}

extension IntObsExt on int {
  SingleValueProvider<int> get provider => SingleValueProvider(this);
}

extension DoubleObsExt on double {
  SingleValueProvider<double> get provider => SingleValueProvider(this);
}

extension SizeIncludeOffset on Size {

}