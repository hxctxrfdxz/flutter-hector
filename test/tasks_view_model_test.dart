import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/task_failure.dart';
import 'package:taskflow/features/tasks/domain/task.dart';
import 'package:taskflow/features/tasks/presentation/tasks_view_model.dart';

import 'fake_task_repository.dart';

const task = Task(
  id: 21,
  title: 'Preparar entrega de TaskFlow',
  description: 'Revisar las pruebas y las evidencias.',
  priority: 'Alta',
  isCompleted: false,
  userId: 2,
);

void main() {
  test(
    'Una respuesta sin tareas termina en estado vacío y sin error',
    () async {
      final model = TasksViewModel(FakeTaskRepository([]));
      addTearDown(model.dispose);

      await model.loadTasks();

      expect(model.tasks, isEmpty);
      expect(model.isLoading, isFalse);
      expect(model.isEmpty, isTrue);
      expect(model.errorMessage, isNull);
    },
  );

  test(
    'Un fallo limpia datos anteriores y un reintento recupera las tareas',
    () async {
      final repository = FakeTaskRepository([task]);
      final model = TasksViewModel(repository);
      addTearDown(model.dispose);
      await model.loadTasks();
      expect(model.findTask(task.id)!.title, task.title);

      repository.loadFailure = const TaskFailure(
        'Revisa tu conexión a internet.',
      );
      await model.loadTasks();
      expect(model.tasks, isEmpty);
      expect(model.isLoading, isFalse);
      expect(model.isEmpty, isFalse);
      expect(model.errorMessage, 'Revisa tu conexión a internet.');

      repository.loadFailure = null;
      await model.loadTasks();
      expect(model.tasks, [task]);
      expect(model.isLoading, isFalse);
      expect(model.isEmpty, isFalse);
      expect(model.errorMessage, isNull);
    },
  );
}
