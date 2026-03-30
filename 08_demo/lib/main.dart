/// Clotho UI Demo - 主程序入口
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/service_locator.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() async {
  // 确保 Flutter 绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化依赖注入容器
  configureDependencies();
  
  runApp(
    ProviderScope(
      child: ClothoUIDemo(),
    ),
  );
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
