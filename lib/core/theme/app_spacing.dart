import 'package:flutter/material.dart';

abstract class AppSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double section = 24;
  static const double screen = 16;

  static const EdgeInsets screenPadding = EdgeInsets.all(screen);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets listPadding = EdgeInsets.fromLTRB(16, 16, 16, 100);
}

abstract class AppRadius {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 12;
  static const double xl = 14;
  static const double pill = 40;
}

abstract class AppIconSize {
  static const double xs = 12;
  static const double sm = 16;
  static const double md = 18;
  static const double lg = 20;
  static const double xl = 24;
  static const double empty = 48;
}
