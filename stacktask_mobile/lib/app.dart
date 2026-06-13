import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stacktask_mobile/src/core/database/database_helper.dart';
import 'package:stacktask_mobile/src/core/repositories/stack_repository.dart';
import 'package:stacktask_mobile/src/core/theme/app_theme.dart';
import 'package:stacktask_mobile/src/ui/screens/stack_screen.dart';
import 'package:stacktask_mobile/src/ui/view_models/stack_view_model.dart';

class StackTasksApp extends StatelessWidget {
  const StackTasksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StackViewModel>(
      future: _createViewModel(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            theme: AppTheme.darkTheme,
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            ),
          );
        }

        if (!snapshot.hasData) {
          return MaterialApp(
            theme: AppTheme.darkTheme,
            debugShowCheckedModeBanner: false,
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final viewModel = snapshot.data!;
        return ChangeNotifierProvider.value(
          value: viewModel,
          child: MaterialApp(
            title: 'StackTasks',
            theme: AppTheme.darkTheme,
            debugShowCheckedModeBanner: false,
            home: const StackScreen(),
          ),
        );
      },
    );
  }

  Future<StackViewModel> _createViewModel() async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    final repository = StackRepository(database: db);
    final vm = StackViewModel(repository: repository);
    await vm.loadCards();
    return vm;
  }
}

