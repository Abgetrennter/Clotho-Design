import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clotho_mvp/main.dart';

void main() {
  testWidgets('ClothoApp smoke test', (WidgetTester tester) async {
    // 构建应用
    await tester.pumpWidget(
      const ProviderScope(
        child: ClothoApp(),
      ),
    );

    // 验证应用启动
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // 验证标题
    expect(find.text('Clotho MVP Demo'), findsOneWidget);
    
    // 验证输入区域提示文本
    expect(find.text('输入消息...'), findsOneWidget);
  });
}
