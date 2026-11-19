import 'package:flutter/foundation.dart';

import '../../../core/task_failure.dart';
import '../data/task_repository.dart';
import '../domain/task.dart';

class TasksViewModel extends ChangeNotifier {
  TasksViewModel(this._repository);

  final TaskRepository _repository;
  List<Task> _tasks = [];
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  List<Task> get tasks => List.unmodifiable(_tasks);
  bool get isEmpty => !isLoading && errorMessage == null && _tasks.isEmpty;

  Future<void> loadTasks() async {
    if (isLoading || isSaving) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _tasks = await _repository.getTasks();
    } on TaskFailure catch (failure) {
      _tasks = [];
      errorMessage = failure.message;
    } catch (error) {
      _tasks = [];
      errorMessage = 'Ocurrió un problema inesperado.';
      debugPrint('Error inesperado: $error');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Task? findTask(int? id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  Future<void> createTask(String title, String description, String priority) {
    return _save(() async {
      final created = await _repository.createTask(
        title,
        description,
        priority,
      );
      _tasks = [..._tasks, created];
    });
  }

  Future<void> updateTask(Task task) {
    return _save(() async {
      await _repository.updateTask(task);
      _tasks = [
        for (final item in _tasks)
          if (item.id == task.id) task else item,
      ];
    });
  }

  Future<void> deleteTask(int id) {
    return _save(() async {
      await _repository.deleteTask(id);
      _tasks = _tasks.where((task) => task.id != id).toList();
    });
  }

  Future<void> _save(Future<void> Function() operation) async {
    if (isLoading || isSaving) {
      throw const TaskFailure('Espera a que termine la operación actual.');
    }
    isSaving = true;
    notifyListeners();
    try {
      await operation();
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void toggleCompleted(int id) {
    if (isLoading || isSaving) return;
    final current = findTask(id);
    if (current == null) return;

    final updated = current.copyWith(isCompleted: !current.isCompleted);
    _repository.save(updated);
    _tasks = [
      for (final task in _tasks)
        if (task.id == id) updated else task,
    ];
    notifyListeners();
  }
}
