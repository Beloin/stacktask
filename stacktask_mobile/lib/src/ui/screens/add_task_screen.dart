import 'package:flutter/material.dart';
import 'package:stacktask_mobile/src/core/models/task_card.dart';
import 'package:stacktask_mobile/src/core/theme/app_theme.dart';
import 'package:stacktask_mobile/src/ui/view_models/stack_view_model.dart';
import 'package:stacktask_mobile/src/ui/widgets/add_task_modal.dart';

class AddTaskScreen extends StatelessWidget {
  final StackViewModel vm;
  final TaskCard? editing;

  const AddTaskScreen({super.key, required this.vm, this.editing});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background1,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          editing == null ? 'New Task' : 'Edit Task',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: AddTaskModal(
          editing: editing,
          onSubmit:
              ({
                required title,
                required tag,
                description = '',
                timeEstimate,
                priority = 1,
              }) {
                final current = editing;
                if (current != null) {
                  vm.updateCard(
                    id: current.id,
                    title: title,
                    tag: tag,
                    description: description,
                    timeEstimate: timeEstimate,
                    priority: priority,
                  );
                } else {
                  vm.addCard(
                    title: title,
                    tag: tag,
                    description: description,
                    timeEstimate: timeEstimate,
                    priority: priority,
                  );
                }
              },
        ),
      ),
    );
  }
}
