/// Clotho UI 设计令牌
/// 对应文档: 00_active_specs/presentation/01-design-tokens.md
library;

import 'package:flutter/material.dart';

/// 间距令牌
class SpacingTokens {
  SpacingTokens._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// 边框半径令牌
class BorderRadiusTokens {
  BorderRadiusTokens._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;
}

/// 阴影令牌
class ShadowTokens {
  ShadowTokens._();

  static List<BoxShadow> get none => [];

  static List<BoxShadow> get sm => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get lg => [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
}

/// 尺寸令牌
class SizeTokens {
  SizeTokens._();

  static const double avatarSmall = 32.0;
  static const double avatarMedium = 40.0;
  static const double avatarLarge = 56.0;

  static const double iconSmall = 20.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;

  static const double navigationRailWidth = 80.0;
  static const double navigationDrawerWidth = 280.0;
  static const double inspectorWidth = 320.0;
}

/// 动画令牌
class AnimationTokens {
  AnimationTokens._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  static const Curve standard = Curves.easeInOut;
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);
}
