import '../domain/task.dart';
import 'task_api_service.dart';
import 'task_repository.dart';

class RemoteTaskRepository implements TaskRepository {
  RemoteTaskRepository(this._apiService);

  final TaskApiService _apiService;
  List<Task> _tasks = [];

  @override
  Future<Task> createTask(
    String title,
    String description,
    String priority,
  ) async {
    final response = await _apiService.createTask(title);
    // La API de práctica puede repetir el id 201 en cada POST.
    var id = response.id;
    while (_tasks.any((task) => task.id == id)) {
      id++;
    }
    final task = Task(
      id: id,
      title: title,
      description: description,
      priority: priority,
      isCompleted: false,
      userId: response.userId,
    );
    _tasks = [..._tasks, task];
    return task;
  }

  @override
  Future<void> updateTask(Task task) async {
    await _apiService.updateTask(task);
    save(task);
  }

  @override
  Future<void> deleteTask(int id) async {
    await _apiService.deleteTask(id);
    _tasks = _tasks.where((task) => task.id != id).toList();
  }

  @override
  Future<List<Task>> getTasks() async {
    _tasks = await _apiService.getTasks();
    return List.unmodifiable(_tasks);
  }

  @override
  void save(Task task) {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) return;
    _tasks[index] = task;
  }
}
