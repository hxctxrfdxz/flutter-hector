import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taskflow/app/taskflow_app.dart';
import 'package:taskflow/features/tasks/data/local_task_repository.dart';
import 'package:taskflow/features/tasks/data/remote_task_repository.dart';
import 'package:taskflow/features/tasks/data/task_api_service.dart';
import 'package:taskflow/features/tasks/domain/task.dart';
import 'package:taskflow/features/tasks/presentation/tasks_view_model.dart';

const remoteTask = Task(
  id: 21,
  title: 'Tarea remota',
  description: 'Sin descripción (API)',
  priority: 'Sin prioridad (API)',
  isCompleted: false,
  userId: 2,
);

class FakeTaskApiService extends TaskApiService {
  bool fail = false;

  @override
  Future<List<Task>> getTasks() async => [remoteTask];

  @override
  Future<Task> createTask(String title) async {
    if (fail) throw StateError('Fallo POST');
    return Task(
      id: 201,
      title: title,
      description: 'Sin descripción (API)',
      priority: 'Sin prioridad (API)',
      isCompleted: false,
      userId: 2,
    );
  }

  @override
  Future<void> updateTask(Task task) async {
    if (fail) throw StateError('Fallo PATCH');
  }

  @override
  Future<void> deleteTask(int id) async {
    if (fail) throw StateError('Fallo DELETE');
  }
}

class FailingTaskRepository extends LocalTaskRepository {
  @override
  Future<Task> createTask(
    String title,
    String description,
    String priority,
  ) async {
    throw StateError('Fallo POST');
  }

  @override
  Future<void> updateTask(Task task) async => throw StateError('Fallo PATCH');

  @override
  Future<void> deleteTask(int id) async => throw StateError('Fallo DELETE');
}

void main() {
  test(
    'CRUD conserva datos ante fallos y distingue ids repetidos de POST',
    () async {
      final api = FakeTaskApiService();
      final viewModel = TasksViewModel(RemoteTaskRepository(api));
      await viewModel.loadTasks();
      await viewModel.createTask('Primera tarea', 'Descripción propia', 'Alta');
      await viewModel.createTask('Segunda tarea', 'Otra descripción', 'Baja');
      expect(viewModel.tasks.map((task) => task.id).toSet().length, 3);
      expect(viewModel.tasks[1].description, 'Descripción propia');
      expect(viewModel.tasks[1].priority, 'Alta');

      api.fail = true;
      await expectLater(
        viewModel.createTask('Falla', '', 'Media'),
        throwsStateError,
      );
      await expectLater(
        viewModel.updateTask(remoteTask.copyWith(title: 'Nuevo título')),
        throwsStateError,
      );
      await expectLater(viewModel.deleteTask(remoteTask.id), throwsStateError);
      expect(viewModel.tasks, hasLength(3));
      expect(viewModel.findTask(21)!.title, remoteTask.title);

      api.fail = false;
      await viewModel.updateTask(remoteTask.copyWith(title: 'Nuevo título'));
      expect(viewModel.findTask(21)!.title, 'Nuevo título');
      await viewModel.deleteTask(21);
      expect(viewModel.findTask(21), isNull);
      expect(viewModel.tasks, hasLength(2));
      viewModel.dispose();
    },
  );

  testWidgets('Edita un título y confirma o cancela la eliminación', (
    tester,
  ) async {
    appRouter.go('/');
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TasksViewModel(LocalTaskRepository())..loadTasks(),
        child: const TaskFlowApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear la bienvenida de TaskFlow'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Editar título'));
    await tester.tap(find.text('Editar título'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'ab');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(
      find.text('El título debe tener al menos 3 caracteres.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byType(TextFormField),
      '  Bienvenida revisada  ',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Bienvenida revisada'), findsOneWidget);
    expect(find.text('Tarea actualizada'), findsOneWidget);

    await tester.ensureVisible(find.text('Volver al listado'));
    await tester.tap(find.text('Volver al listado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bienvenida revisada'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Eliminar tarea'));
    await tester.tap(find.text('Eliminar tarea'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Bienvenida revisada'), findsOneWidget);

    await tester.tap(find.text('Eliminar tarea'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(appRouter.state.uri.path, '/');
    expect(find.text('Bienvenida revisada'), findsNothing);
    expect(find.text('Tarea eliminada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Los fallos de creación, edición y eliminación muestran error', (
    tester,
  ) async {
    appRouter.go('/');
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TasksViewModel(FailingTaskRepository())..loadTasks(),
        child: const TaskFlowApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva tarea'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Tarea fallida');
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudo crear la tarea'), findsOneWidget);
    expect(find.text('Tarea creada'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear la bienvenida de TaskFlow'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Editar título'));
    await tester.tap(find.text('Editar título'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Cambio fallido');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudo actualizar la tarea'), findsOneWidget);
    expect(find.text('Crear la bienvenida de TaskFlow'), findsOneWidget);
    expect(find.text('Tarea actualizada'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Eliminar tarea'));
    await tester.tap(find.text('Eliminar tarea'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudo eliminar la tarea'), findsOneWidget);
    expect(appRouter.state.uri.path, '/task/1');
    expect(find.text('Crear la bienvenida de TaskFlow'), findsOneWidget);
    expect(find.text('Tarea eliminada'), findsNothing);
  });
}
