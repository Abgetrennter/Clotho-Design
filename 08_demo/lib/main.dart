/// Clotho UI Demo - 主程序入口
library;

import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ClothoUIDemo());
}

/// Clotho UI Demo 应用
class ClothoUIDemo extends StatelessWidget {
  const ClothoUIDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clotho UI Demo',
      debugShowCheckedModeBanner: false,
      theme: ClothoTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
