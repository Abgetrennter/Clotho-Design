/// 响应式三栏布局组件
/// 对应文档: 00_active_specs/presentation/04-responsive-layout.md
library;

import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

/// 响应式断点
enum ResponsiveBreakpoint {
  /// 移动端 (< 600px)
  mobile,
  /// 平板端 (600px - 1200px)
  tablet,
  /// 桌面端 (> 1200px)
  desktop,
}

/// 响应式布局组件
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.navigation,
    required this.stage,
    this.inspector,
  });

  final Widget navigation;
  final Widget stage;
  final Widget? inspector;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoint = _getBreakpoint(constraints.maxWidth);

        return _buildLayout(context, breakpoint);
      },
    );
  }

  /// 获取断点
  ResponsiveBreakpoint _getBreakpoint(double width) {
    if (width < 600) {
      return ResponsiveBreakpoint.mobile;
    } else if (width < 1200) {
      return ResponsiveBreakpoint.tablet;
    } else {
      return ResponsiveBreakpoint.desktop;
    }
  }

  /// 构建布局
  Widget _buildLayout(BuildContext context, ResponsiveBreakpoint breakpoint) {
    switch (breakpoint) {
      case ResponsiveBreakpoint.mobile:
        return _buildMobileLayout(context);
      case ResponsiveBreakpoint.tablet:
        return _buildTabletLayout(context);
      case ResponsiveBreakpoint.desktop:
        return _buildDesktopLayout(context);
    }
  }

  /// 构建移动端布局
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      body: stage,
      drawer: Drawer(
        width: SizeTokens.navigationDrawerWidth,
        child: navigation,
      ),
    );
  }

  /// 构建平板端布局
  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: SizeTokens.navigationRailWidth,
          child: navigation,
        ),
        Expanded(child: stage),
      ],
    );
  }

  /// 构建桌面端布局
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: SizeTokens.navigationRailWidth,
          child: navigation,
        ),
        Expanded(
          child: stage,
        ),
        if (inspector != null)
          SizedBox(
            width: SizeTokens.inspectorWidth,
            child: inspector,
          ),
      ],
    );
  }
}
