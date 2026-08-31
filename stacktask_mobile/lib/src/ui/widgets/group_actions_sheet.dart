import 'package:flutter/material.dart';
import 'package:stacktask_mobile/src/core/theme/app_theme.dart';

class GroupActionsSheet extends StatelessWidget {
  final bool canDelete;
  final ValueChanged<String> onRename;
  final VoidCallback onDelete;

  const GroupActionsSheet({
    super.key,
    required this.canDelete,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: Colors.white),
            title: const Text(
              'Rename',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Navigator.of(context).pop();
              final controller = TextEditingController();
              showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.modalBackground,
                  title: const Text(
                    'Rename Group',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: TextField(
                    controller: controller,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        final value = controller.text.trim();
                        if (value.isEmpty) return;
                        Navigator.of(ctx).pop(value);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ).then((value) {
                if (value != null && value.isNotEmpty) onRename(value);
              });
            },
          ),
          if (canDelete)
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: AppColors.danger,
              ),
              title: Text(
                'Delete',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                onDelete();
              },
            ),
        ],
      ),
    );
  }
}
