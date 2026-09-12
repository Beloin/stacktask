import 'package:flutter/material.dart';
import 'package:stacktask_mobile/src/core/state/state_service.dart';
import 'package:stacktask_mobile/src/core/theme/app_theme.dart';
import 'package:stacktask_mobile/src/ui/screens/stack_screen.dart';

class StackTasksApp extends StatelessWidget {
  final StateService stateService;

  const StackTasksApp({super.key, required this.stateService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StackTasks',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: StackScreen(stateService: stateService),
    );
  }
}
