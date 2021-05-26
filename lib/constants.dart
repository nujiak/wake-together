import 'dart:core';
class Days {
  /// Prime number held by the day.
  final int value;

  /// Private constructor to prevent other Days from being created.
  const Days._(this.value);

  static const Days MONDAY = Days._(3);
  static const Days TUESDAY = Days._(5);
  static const Days WEDNESDAY = Days._(7);
  static const Days THURSDAY = Days._(11);
  static const Days FRIDAY = Days._(13);
  static const Days SATURDAY = Days._(17);
  static const Days SUNDAY = Days._(19);

  /// A set of all Days.
  static const Set<Days> all = {MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY};
  static const List<Days> allList = [MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY];

  /// A map of each Day to a one-letter String.
  static const Map<Days, String> shortStrings = {
    MONDAY: "M",
    TUESDAY: "T",
    WEDNESDAY: "W",
    THURSDAY: "T",
    FRIDAY: "F",
    SATURDAY: "S",
    SUNDAY: "S",
  };

  static const Map<Days, int> DATETIME_WEEKDAY = {
    MONDAY: DateTime.monday,
    TUESDAY: DateTime.tuesday,
    WEDNESDAY: DateTime.wednesday,
    THURSDAY: DateTime.thursday,
    FRIDAY: DateTime.friday,
    SATURDAY: DateTime.saturday,
    SUNDAY: DateTime.sunday,
  };
}

