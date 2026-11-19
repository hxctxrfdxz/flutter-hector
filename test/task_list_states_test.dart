import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taskflow/core/task_failure.dart';
import 'package:taskflow/features/tasks/data/local_task_repository.dart';
import 'package:taskflow/features/tasks/domain/task.dart';
import 'package:taskflow/features/tasks/presentation/task_list_screen.dart';
import 'package:taskflow/features/tasks/presentation/tasks_view_model.dart';

class ControlledTaskRepository extends LocalTaskRepository {
  final requests = <Completer<List<Task>>>[];

  @override
  Future<List<Task>> getTasks() {
    final request = Completer<List<Task>>();
    requests.add(request);
    return request.future;
  }

  @override
  void save(Task task) {}
}

const testTask = Task(
  id: 21,
  title: 'Tarea del usuario 2',
  description: 'Sin descripción (API)',
  priority: 'Sin prioridad (API)',
  isCompleted: false,
  userId: 2,
);

void main() {
  testWidgets(
    'Carga, actualiza, muestra error y recupera datos con Reintentar',
    (tester) async {
      final repository = ControlledTaskRepository();
      final viewModel = TasksViewModel(repository);
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => viewModel..loadTasks(),
          child: const MaterialApp(home: TaskListScreen()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(viewModel.isEmpty, isFalse);
      expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed,
        isNull,
      );
      await viewModel.loadTasks();
      expect(repository.requests, hasLength(1));

      repository.requests[0].complete([testTask]);
      await tester.pumpAndSettle();
      expect(find.text(testTask.title), findsOneWidget);

      await tester.tap(find.byTooltip('Actualizar tareas'));
      await tester.pump();
      expect(repository.requests, hasLength(2));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      repository.requests[1].completeError(
        const TaskFailure('Revisa tu conexión a internet.'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Revisa tu conexión a internet.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text(testTask.title), findsNothing);
      expect(viewModel.tasks, isEmpty);
      expect(viewModel.isEmpty, isFalse);

      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      expect(repository.requests, hasLength(3));
      expect(viewModel.errorMessage, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      repository.requests[2].complete([testTask]);
      await tester.pumpAndSettle();
      expect(find.text(testTask.title), findsOneWidget);
      expect(find.text('Reintentar'), findsNothing);
      expect(viewModel.errorMessage, isNull);
    },
  );

  testWidgets('Distingue vacío y permite actualizar por botón y por gesto', (
    tester,
  ) async {
    final repository = ControlledTaskRepository();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TasksViewModel(repository)..loadTasks(),
        child: const MaterialApp(home: TaskListScreen()),
      ),
    );

    repository.requests[0].complete([]);
    await tester.pumpAndSettle();
    expect(find.text('Todavía no hay tareas para mostrar.'), findsOneWidget);
    expect(find.text('Actualizar'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);

    await tester.tap(find.text('Actualizar'));
    await tester.pump();
    expect(repository.requests, hasLength(2));
    repository.requests[1].complete([testTask]);
    await tester.pumpAndSettle();
    expect(find.text(testTask.title), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, 350));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(repository.requests, hasLength(3));
    repository.requests[2].complete([testTask]);
    await tester.pumpAndSettle();
    expect(find.text(testTask.title), findsOneWidget);
  });
}
