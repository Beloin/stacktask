import 'package:flutter/material.dart';
import 'package:stacktask_mobile/src/core/database/database_helper.dart';
import 'package:stacktask_mobile/src/core/repositories/stack_repository.dart';
import 'package:stacktask_mobile/src/core/theme/app_theme.dart';
import 'package:stacktask_mobile/src/ui/screens/stack_screen.dart';
import 'package:stacktask_mobile/src/ui/view_models/stack_view_model.dart';

class StackTasksApp extends StatelessWidget {
  const StackTasksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StackTasks',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<StackViewModel>(
        future: _createViewModel(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return StackScreen(viewModel: snapshot.data!);
          }
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Future<StackViewModel> _createViewModel() async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    final repository = StackRepository(database: db);
    return StackViewModel(repository: repository);
  }
}