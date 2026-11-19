import '../domain/task.dart';
import 'task_repository.dart';

class LocalTaskRepository implements TaskRepository {
  final List<Task> _tasks = <Task>[
    Task(
      id: 1,
      title: 'Crear la bienvenida de TaskFlow',
      description:
          'Mostrar el nombre del estudiante y el mensaje de bienvenida.',
      priority: 'Alta',
      isCompleted: true,
      userId: 1,
    ),
    Task(
      id: 2,
      title: 'Agregar el contador interactivo',
      description:
          'Agregar y completar tareas con setState y un objetivo diario.',
      priority: 'Alta',
      isCompleted: true,
      userId: 1,
    ),
    Task(
      id: 3,
      title: 'Construir el listado local',
      description: 'Representar cinco tareas con ListView.builder y TaskCard.',
      priority: 'Alta',
      isCompleted: true,
      userId: 1,
    ),
    Task(
      id: 4,
      title: 'Verificar las tarjetas de tareas',
      description:
          'Revisar la prioridad, el estado y el desplazamiento de la lista.',
      priority: 'Media',
      isCompleted: false,
      userId: 1,
    ),
    Task(
      id: 5,
      title: 'Guardar la evidencia de la sesión 5',
      description: 'Capturar el listado y el detalle con el usuario de prueba.',
      priority: 'Baja',
      isCompleted: false,
      userId: 1,
    ),
  ];

  @override
  List<Task> getTasks() => List.unmodifiable(_tasks);

  @override
  void save(Task task) {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) return;
    _tasks[index] = task;
  }
}
