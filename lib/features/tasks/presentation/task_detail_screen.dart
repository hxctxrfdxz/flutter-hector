import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/task_failure.dart';
import '../domain/task.dart';
import 'tasks_view_model.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final int? taskId;

  Future<void> _editTitle(BuildContext context, Task task) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditTitleDialog(task: task),
    );
    if (!context.mounted || saved != true) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Tarea actualizada')));
  }

  Future<void> _deleteTask(BuildContext context, Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Eliminar ${task.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await context.read<TasksViewModel>().deleteTask(task.id);
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
      messenger.clearSnackBars();
      messenger.showSnackBar(const SnackBar(content: Text('Tarea eliminada')));
    } on TaskFailure catch (failure) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
    } catch (error) {
      debugPrint('Error inesperado al eliminar: $error');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrió un problema inesperado.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TasksViewModel>();
    final task = viewModel.findTask(taskId);
    final isSaving = viewModel.isSaving;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de tarea')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (task == null)
            const Text('No se encontró esta tarea.')
          else ...[
            Text(task.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text(task.description),
            const SizedBox(height: 16),
            Chip(label: Text('Prioridad: ${task.priority}')),
            const SizedBox(height: 12),
            Text(task.isCompleted ? 'Estado: completada' : 'Estado: pendiente'),
            Text('Usuario: ${task.userId}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () {
                      context.read<TasksViewModel>().toggleCompleted(task.id);
                    },
              child: Text(
                task.isCompleted
                    ? 'Marcar como pendiente'
                    : 'Marcar como completada',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isSaving ? null : () => _editTitle(context, task),
              icon: const Icon(Icons.edit),
              label: const Text('Editar título'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isSaving ? null : () => _deleteTask(context, task),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar tarea'),
            ),
            if (isSaving) ...[
              const SizedBox(height: 12),
              const Text('Guardando cambios...'),
            ],
          ],
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver al listado'),
          ),
        ],
      ),
    );
  }
}

class _EditTitleDialog extends StatefulWidget {
  const _EditTitleDialog({required this.task});

  final Task task;

  @override
  State<_EditTitleDialog> createState() => _EditTitleDialogState();
}

class _EditTitleDialogState extends State<_EditTitleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.task.title);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final viewModel = context.read<TasksViewModel>();
    if (viewModel.isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);
    try {
      await viewModel.updateTask(
        widget.task.copyWith(title: _controller.text.trim()),
      );
      if (mounted) Navigator.pop(context, true);
    } on TaskFailure catch (failure) {
      if (mounted) setState(() => _errorMessage = failure.message);
    } catch (error) {
      debugPrint('Error inesperado al editar: $error');
      if (mounted) {
        setState(() => _errorMessage = 'Ocurrió un problema inesperado.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<TasksViewModel>().isSaving;
    return PopScope(
      canPop: !isSaving,
      child: AlertDialog(
        title: const Text('Editar título'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                enabled: !isSaving,
                controller: _controller,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (value) {
                  if ((value?.trim() ?? '').length < 3) {
                    return 'El título debe tener al menos 3 caracteres.';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isSaving ? null : () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: isSaving ? null : _save,
            child: Text(isSaving ? 'Guardando...' : 'Guardar'),
          ),
        ],
      ),
    );
  }
}
