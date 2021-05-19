import 'dart:core';
class Days {
  final int value;

  const Days._(this.value);

  static const Days MONDAY = Days._(3);
  static const Days TUESDAY = Days._(5);
  static const Days WEDNESDAY = Days._(7);
  static const Days THURSDAY = Days._(11);
  static const Days FRIDAY = Days._(13);
  static const Days SATURDAY = Days._(17);
  static const Days SUNDAY = Days._(19);

  static const Set<Days>all = {MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY};
}

