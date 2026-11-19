import 'package:taskflow/core/task_failure.dart';
import 'package:taskflow/features/tasks/data/task_repository.dart';
import 'package:taskflow/features/tasks/domain/task.dart';

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository(List<Task> items) : items = List.of(items);

  final List<Task> items;
  TaskFailure? loadFailure;

  @override
  Future<List<Task>> getTasks() async {
    final failure = loadFailure;
    if (failure != null) throw failure;
    return List.of(items);
  }

  @override
  void save(Task task) {
    final index = items.indexWhere((item) => item.id == task.id);
    if (index >= 0) items[index] = task;
  }

  @override
  Future<Task> createTask(
    String title,
    String description,
    String priority,
  ) async {
    var nextId = 1;
    for (final task in items) {
      if (task.id >= nextId) nextId = task.id + 1;
    }
    final task = Task(
      id: nextId,
      title: title,
      description: description,
      priority: priority,
      isCompleted: false,
      userId: 2,
    );
    items.add(task);
    return task;
  }

  @override
  Future<void> updateTask(Task task) async => save(task);

  @override
  Future<void> deleteTask(int id) async {
    items.removeWhere((task) => task.id == id);
  }
}
