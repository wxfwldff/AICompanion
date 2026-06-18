import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/chat_page.dart';
import 'pages/moments_page.dart';
import 'pages/settings_page.dart';
import 'core/ui_controller.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // 监听全局主题变化
    uiController.themeColor.addListener(_onThemeChange);
  }

  void _onThemeChange() => setState(() {});

  @override
  void dispose() {
    uiController.themeColor.removeListener(_onThemeChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      scaffoldBackgroundColor: uiController.themeColor.value,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'AI Social',
      debugShowCheckedModeBanner: false,
      theme: theme,
      initialRoute: '/home',
      onGenerateRoute: (settings) {
        // 聊天页：可接收 characterName / characterEmoji 参数
        if (settings.name == '/chat') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (_) => ChatPage(
              characterName: args?['name'] as String? ?? '小晴',
              characterEmoji: args?['emoji'] as String? ?? '🌸',
            ),
          );
        }
        // 朋友圈页
        if (settings.name == '/moments') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (_) => MomentsPage(
              characterName: args?['name'] as String? ?? '小晴',
              characterEmoji: args?['emoji'] as String? ?? '🌸',
            ),
          );
        }
        // 首页
        if (settings.name == '/home') {
          return MaterialPageRoute(builder: (_) => const HomePage());
        }
        // 设置页
        if (settings.name == '/settings') {
          return MaterialPageRoute(builder: (_) => const SettingsPage());
        }
        return MaterialPageRoute(builder: (_) => const HomePage());
      },
    );
  }
}
