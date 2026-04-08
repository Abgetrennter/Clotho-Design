import 'package:flutter/material.dart';

class SpacingTokens {
  SpacingTokens._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class BorderRadiusTokens {
  BorderRadiusTokens._();

  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double full = 999;
}

class SizeTokens {
  SizeTokens._();

  static const double shellMaxWidth = 1440;
  static const double inspectorPanelWidth = 360;
}

class MotionTokens {
  MotionTokens._();

  static const Duration fast = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 260);
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
}
