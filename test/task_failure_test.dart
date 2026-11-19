import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taskflow/app/taskflow_app.dart';
import 'package:taskflow/core/task_failure.dart';
import 'package:taskflow/features/tasks/data/local_task_repository.dart';
import 'package:taskflow/features/tasks/data/remote_task_repository.dart';
import 'package:taskflow/features/tasks/data/task_api_service.dart';
import 'package:taskflow/features/tasks/domain/task.dart';
import 'package:taskflow/features/tasks/presentation/tasks_view_model.dart';

const createdTask = Task(
  id: 6,
  title: 'Preparar evidencia',
  description: '',
  priority: 'Media',
  isCompleted: false,
  userId: 1,
);

class FailureApiService extends TaskApiService {
  late Object failure;

  @override
  Future<List<Task>> getTasks() async => throw failure;

  @override
  Future<Task> createTask(String title) async => throw failure;

  @override
  Future<void> updateTask(Task task) async => throw failure;

  @override
  Future<void> deleteTask(int id) async => throw failure;
}

class PendingTaskRepository extends LocalTaskRepository {
  final creations = <Completer<Task>>[];
  final updates = <Completer<void>>[];

  @override
  Future<Task> createTask(String title, String description, String priority) {
    final request = Completer<Task>();
    creations.add(request);
    return request.future;
  }

  @override
  Future<void> updateTask(Task task) {
    final request = Completer<void>();
    updates.add(request);
    return request.future;
  }
}

void main() {
  test(
    'Traduce conexión, timeout, HTTP y formato para las operaciones CRUD',
    () async {
      final options = RequestOptions(path: '/todos');
      final cases = <Object, String>{
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ): 'Revisa tu conexión a internet.',
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        ): 'El servidor tardó demasiado.',
        DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        ): 'El servidor tardó demasiado.',
        DioException(
          requestOptions: options,
          type: DioExceptionType.sendTimeout,
        ): 'El servidor tardó demasiado.',
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: 404),
        ): 'La API respondió con HTTP 404.',
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: 500),
        ): 'La API respondió con HTTP 500.',
        const FormatException('JSON inválido'):
            'La API devolvió datos inesperados.',
      };
      final api = FailureApiService();
      final repository = RemoteTaskRepository(api);
      for (final entry in cases.entries) {
        api.failure = entry.key;
        final matcher = throwsA(
          isA<TaskFailure>().having(
            (failure) => failure.message,
            'message',
            entry.value,
          ),
        );
        await expectLater(repository.getTasks(), matcher);
        await expectLater(
          repository.createTask('Prueba', '', 'Media'),
          matcher,
        );
        await expectLater(repository.updateTask(createdTask), matcher);
        await expectLater(repository.deleteTask(6), matcher);
      }
    },
  );

  testWidgets('Bloquea Guardar y conserva los campos tras un fallo de envío', (
    tester,
  ) async {
    appRouter.go('/');
    final repository = PendingTaskRepository();
    final viewModel = TasksViewModel(repository);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => viewModel..loadTasks(),
        child: const TaskFlowApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva tarea'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, createdTask.title);
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(viewModel.isSaving, isTrue);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Guardando...'),
          )
          .onPressed,
      isNull,
    );
    await expectLater(
      viewModel.createTask('Duplicado', '', 'Media'),
      throwsA(isA<TaskFailure>()),
    );
    await viewModel.loadTasks();
    expect(repository.creations, hasLength(1));

    repository.creations[0].completeError(
      const TaskFailure('Revisa tu conexión a internet.'),
    );
    await tester.pumpAndSettle();
    expect(viewModel.isSaving, isFalse);
    expect(find.text('Revisa tu conexión a internet.'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, createdTask.title),
      findsOneWidget,
    );
    expect(find.text('Tarea creada'), findsNothing);
    expect(repository.creations, hasLength(1));

    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(repository.creations, hasLength(2));
    repository.creations[1].complete(createdTask);
    await tester.pumpAndSettle();
    expect(appRouter.state.uri.path, '/');
    expect(viewModel.isSaving, isFalse);
    expect(find.text('Tarea creada'), findsOneWidget);

    await tester.scrollUntilVisible(find.text(createdTask.title), 150);
    await tester.tap(find.text(createdTask.title));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Editar título'));
    await tester.tap(find.text('Editar título'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Título editado');
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(viewModel.isSaving, isTrue);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Guardando...'),
          )
          .onPressed,
      isNull,
    );
    await expectLater(
      viewModel.updateTask(createdTask),
      throwsA(isA<TaskFailure>()),
    );
    expect(repository.updates, hasLength(1));
    repository.updates[0].completeError(
      const TaskFailure('El servidor tardó demasiado.'),
    );
    await tester.pumpAndSettle();
    expect(viewModel.isSaving, isFalse);
    expect(find.text('El servidor tardó demasiado.'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Título editado'),
      findsOneWidget,
    );
    expect(viewModel.findTask(6)!.title, createdTask.title);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
