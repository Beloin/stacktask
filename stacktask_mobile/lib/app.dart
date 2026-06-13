import 'package:flutter/material.dart';
import 'package:stacktask_mobile/src/core/theme/app_theme.dart';
import 'package:stacktask_mobile/src/ui/screens/stack_screen.dart';

class StackTasksApp extends StatelessWidget {
  const StackTasksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StackTasks',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const StackScreen(),
    );
  }
}