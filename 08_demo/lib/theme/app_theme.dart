/// Clotho UI 主题配置
/// 对应文档: 00_active_specs/presentation/02-color-theme.md
library;

import 'package:flutter/material.dart';

/// Clotho 深色主题
class ClothoTheme {
  ClothoTheme._();

  static const Color _seedColor = Color(0xFF6750A4);

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,

      // AppBar 主题
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
      ),

      // NavigationRail 主题
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        selectedIconTheme: IconThemeData(color: scheme.onSecondaryContainer),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(
          color: scheme.onSecondaryContainer,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),

      // NavigationDrawer 主题
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
      ),

      // Card 主题
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ListTile 主题
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
      ),

      // Divider 主题
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),

      // InputDecoration 主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),

      // Chip 主题
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.secondaryContainer,
        labelStyle: TextStyle(color: scheme.onSurface),
      ),

      // FloatingActionButton 主题
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: 4,
      ),
    );
  }
}
