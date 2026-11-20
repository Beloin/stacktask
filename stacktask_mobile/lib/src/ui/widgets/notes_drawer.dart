import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stacktask_mobile/src/core/models/note.dart';
import 'package:stacktask_mobile/src/core/theme/app_theme.dart';
import 'package:stacktask_mobile/src/ui/view_models/stack_view_model.dart';
import 'package:stacktask_mobile/src/ui/widgets/note_card_widget.dart';
import 'package:stacktask_mobile/src/ui/widgets/note_detail_modal.dart';
import 'package:stacktask_mobile/src/ui/widgets/note_editor_sheet.dart';

class NotesDrawer extends StatelessWidget {
  const NotesDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background1,
      child: SafeArea(
        child: Consumer<StackViewModel>(
          builder: (context, vm, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Text(
                    'NOTES',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 2.5,
                        ),
                  ),
                ),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.extentAfter < 200) {
                        vm.loadMoreNotes();
                      }
                      return false;
                    },
                    child: ReorderableListView.builder(
                      itemCount: vm.visibleNotesCount > vm.notes.length
                          ? vm.notes.length
                          : vm.visibleNotesCount,
                      onReorderItem: (oldIndex, newIndex) {
                        vm.moveNoteTo(oldIndex, newIndex);
                      },
                      itemBuilder: (context, i) {
                        final note = vm.notes[i];
                        return NoteCardWidget(
                          key: ValueKey(note.id),
                          note: note,
                          onTap: () => _showNoteDetail(context, vm, note),
                        );
                      },
                    ),
                  ),
                ),
                const Divider(height: 1, color: Colors.white12),
                InkWell(
                  onTap: () => _showNoteEditor(context, vm, null),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add, color: AppColors.accentLight),
                        SizedBox(width: 12),
                        Text(
                          'New Note',
                          style: TextStyle(
                            color: AppColors.accentLight,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showNoteEditor(BuildContext context, StackViewModel vm, Note? editing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.modalBackground,
      builder: (modalContext) => ChangeNotifierProvider.value(
        value: vm,
        child: NoteEditorSheet(
          editing: editing,
          onSubmit: ({required title, required description}) {
            if (editing == null) {
              vm.addNote(title: title, description: description);
            } else {
              vm.updateNote(
                id: editing.id,
                title: title,
                description: description,
              );
            }
          },
        ),
      ),
    );
  }

  void _showNoteDetail(BuildContext context, StackViewModel vm, Note note) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NoteDetailSheet(
        note: note,
        onDismiss: () => Navigator.of(context).pop(),
        onDelete: () {
          Navigator.of(context).pop();
          vm.deleteNote(note.id);
        },
        onEdit: () {
          Navigator.of(context).pop();
          _showNoteEditor(context, vm, note);
        },
      ),
    );
  }
}

class _NoteDetailSheet extends StatelessWidget {
  final Note note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDismiss;

  const _NoteDetailSheet({
    required this.note,
    required this.onEdit,
    required this.onDelete,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black54,
        child: DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return NoteDetailModal(
              note: note,
              onEdit: onEdit,
              onDelete: onDelete,
            );
          },
        ),
      ),
    );
  }
}
