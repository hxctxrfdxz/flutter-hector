import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/task_failure.dart';
import 'tasks_view_model.dart';

class TaskDraft {
  const TaskDraft(this.title, this.description, this.priority, {this.dueDate});

  final String title;
  final String description;
  final String priority;
  final DateTime? dueDate;
}

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  String _priority = 'Media';
  DateTime? _dueDate;
  String? _errorMessage;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Selecciona una fecha',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (!mounted || selected == null) return;
    setState(() => _dueDate = selected);
  }

  Future<void> _submit() async {
    final viewModel = context.read<TasksViewModel>();
    if (viewModel.isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final draft = TaskDraft(
      _title.text.trim(),
      _description.text.trim(),
      _priority,
      dueDate: _dueDate,
    );
    setState(() => _errorMessage = null);
    try {
      await viewModel.createTask(
        draft.title,
        draft.description,
        draft.priority,
      );
      if (mounted) context.pop(draft);
    } on TaskFailure catch (failure) {
      if (mounted) setState(() => _errorMessage = failure.message);
    } catch (error) {
      debugPrint('Error inesperado al crear: $error');
      if (mounted) {
        setState(() => _errorMessage = 'Ocurrió un problema inesperado.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<TasksViewModel>().isSaving;
    final selectedDate = _dueDate;
    final dateLabel = selectedDate == null
        ? 'Elegir fecha (opcional)'
        : 'Fecha: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';

    return PopScope(
      canPop: !isSaving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Nueva tarea')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                enabled: !isSaving,
                controller: _title,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (value) {
                  final title = value?.trim() ?? '';
                  if (title.isEmpty) return 'Escribe el título de tu tarea.';
                  if (title.length < 3) {
                    return 'El título debe tener al menos 3 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                enabled: !isSaving,
                controller: _description,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Prioridad'),
                items: ['Alta', 'Media', 'Baja']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: isSaving
                    ? null
                    : (value) => setState(() => _priority = value ?? 'Media'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isSaving ? null : _selectDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(dateLabel),
                    ),
                  ),
                  if (selectedDate != null)
                    IconButton(
                      tooltip: 'Quitar fecha',
                      onPressed: isSaving
                          ? null
                          : () => setState(() => _dueDate = null),
                      icon: const Icon(Icons.clear),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: isSaving ? null : _submit,
                child: Text(isSaving ? 'Guardando...' : 'Guardar'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: isSaving ? null : () => context.pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
