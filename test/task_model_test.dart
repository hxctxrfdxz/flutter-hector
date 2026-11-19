import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/features/tasks/domain/task.dart';

void main() {
  test('Convierte tareas remotas y conserva el formato local', () {
    final remote = Task.fromJson({
      'id': 21,
      'title': 'Tarea remota',
      'completed': false,
      'userId': 2,
    });
    expect(remote.id, 21);
    expect(remote.title, 'Tarea remota');
    expect(remote.description, 'Sin descripción (API)');
    expect(remote.priority, 'Sin prioridad (API)');
    expect(remote.isCompleted, isFalse);
    expect(remote.userId, 2);

    final local = Task.fromJson({
      'id': 1,
      'title': 'Tarea local',
      'description': 'Descripción propia',
      'priority': 'Alta',
      'isCompleted': true,
      'userId': 1,
    });
    expect(local.description, 'Descripción propia');
    expect(local.priority, 'Alta');
    expect(local.isCompleted, isTrue);
  });
}
