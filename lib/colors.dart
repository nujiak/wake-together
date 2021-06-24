import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Provides a colour derived from a string's hash.
Color toColor(String text, {double saturation = .7, double value = 1}) {
  return HSVColor
      .fromAHSV(1, (text.hashCode / 255) % 255, saturation, value)
      .toColor();
}

/// Contains gradients that are themed according to time of day.
class Gradients {

  /// Starting color for the midnight gradient.
  static const midnightStart = Color(0xff16133b);

  /// Ending color for the midnight gradient.
  static const midnightEnd = Color(0xff06070e);

  /// 2-color radial gradient for 12am.
  static const RadialGradient midnight = RadialGradient(
    colors: [midnightStart, midnightEnd],
    radius: 3,
    center: Alignment(-.8,-.8),
  );

  /// Starting color for the dawn gradient.
  static const dawnStart = Color(0xffbf4f05);

  /// Ending color for the dawn gradient.
  static const dawnEnd = Color(0xff742227);

  /// 2-color radial gradient for 6am.
  static const RadialGradient dawn = RadialGradient(
    colors: [dawnStart, dawnEnd],
    radius: 3,
    center: Alignment(-.8,-.8),
  );

  /// Starting color for the day gradient.
  static const dayStart = Color(0xff0b8793);

  /// Ending color for the day gradient.
  static const dayEnd = Color(0xff126ac9);

  /// 2-color radial gradient for 12pm.
  static const RadialGradient day = RadialGradient(
    colors: [dayStart, dayEnd],
    radius: 3,
    center: Alignment(-.8,-.8),
  );

  /// Starting color for the dusk gradient.
  static const duskStart = Color(0xffaf2d1d);

  /// Ending color for the dusk gradient.
  static const duskEnd = Color(0xff521d68);

  /// 2-color radial gradient for 6pm.
  static const RadialGradient dusk = RadialGradient(
    colors: <Color>[duskStart, duskEnd],
    radius: 3,
    center: Alignment(-.8,-.8),
  );

  /// Gives the gradient for a particular time in a day.
  static Gradient getGradient(int hours, int minutes) {
    int totalMinutes = hours * 60 + minutes;
    if (hours < 6) {
      return midnight.lerpFrom(dawn, (6 * 60 - totalMinutes) / (6 * 60))!;
    }
    if (hours < 12) {
      return dawn.lerpFrom(day, (12 * 60 - totalMinutes) / (6 * 60))!;
    }
    if (hours < 18) {
      return day.lerpFrom(dusk, (18 * 60 - totalMinutes) / (6 * 60))!;
    }
    return dusk.lerpFrom(midnight, (24 * 60 - totalMinutes) / (6 * 60))!;
  }
}

/// Allows color modification using HSV values by converting between
/// HSVColor.
extension HSVModification on Color {

  /// Returns the Color with a new hue.
  Color withHue(double hue) {
    return HSVColor.fromColor(this).withHue(hue).toColor();
  }

  /// Returns the Color with a new saturation.
  Color withSaturation(double sat) {
    return HSVColor.fromColor(this).withSaturation(sat).toColor();
  }

  /// Returns the Color with a new value.
  Color withValue(double value) {
    return HSVColor.fromColor(this).withValue(value).toColor();
  }
}