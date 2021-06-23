import 'dart:ui';

import 'package:flutter/cupertino.dart';

/// Provides a colour derived from a string's hash.
Color toColor(String text, {double saturation = .7, double value = 1}) {
  return HSVColor
      .fromAHSV(1, (text.hashCode / 255) % 255, saturation, value)
      .toColor();
}