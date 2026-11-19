import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taskflow/app/taskflow_app.dart';
import 'package:taskflow/features/tasks/data/local_task_repository.dart';
import 'package:taskflow/features/tasks/domain/task.dart';
import 'package:taskflow/features/tasks/presentation/tasks_view_model.dart';
import 'package:taskflow/features/tasks/presentation/welcome_screen.dart';

Widget buildTestApp() {
  return ChangeNotifierProvider<TasksViewModel>(
    create: (_) => TasksViewModel(LocalTaskRepository())..loadTasks(),
    child: const TaskFlowApp(),
  );
}

void main() {
  test('Convierte tareas remotas y conserva el formato local', () {
    final remote = Task.fromJson({
      'id': 21,
      'title': 'Tarea remota',
      'completed': false,
      'userId': 2,
    });
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

  testWidgets('El listado muestra tareas locales y permite desplazarse', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();
    expect(find.text('Mis tareas'), findsOneWidget);
    expect(find.text('Crear la bienvenida de TaskFlow'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsWidgets);
    expect(find.byIcon(Icons.chevron_right), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Guardar la evidencia de la sesión 5'),
      150,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Guardar la evidencia de la sesión 5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Abre tres tareas por id y vuelve al listado', (tester) async {
    appRouter.go('/');
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final tasks = await LocalTaskRepository().getTasks();
    for (final task in tasks.take(3)) {
      await tester.tap(find.text(task.title));
      await tester.pumpAndSettle();

      expect(find.text('Detalle de tarea'), findsOneWidget);
      expect(find.text(task.title), findsOneWidget);
      expect(find.text(task.description), findsOneWidget);
      expect(find.text('Prioridad: ${task.priority}'), findsOneWidget);
      expect(find.text('Usuario: ${task.userId}'), findsOneWidget);
      expect(
        find.text(
          task.isCompleted ? 'Estado: completada' : 'Estado: pendiente',
        ),
        findsOneWidget,
      );
      expect(appRouter.state.uri.path, '/task/${task.id}');

      await tester.tap(
        find.text(
          task.isCompleted ? 'Marcar como pendiente' : 'Marcar como completada',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          task.isCompleted ? 'Estado: pendiente' : 'Estado: completada',
        ),
        findsOneWidget,
      );

      if (task.id == 2) {
        await tester.pageBack();
      } else {
        await tester.ensureVisible(find.text('Volver al listado'));
        await tester.tap(find.text('Volver al listado'));
      }
      await tester.pumpAndSettle();
      expect(find.text('Mis tareas'), findsOneWidget);
      expect(appRouter.state.uri.path, '/');
      final card = find.ancestor(
        of: find.text(task.title),
        matching: find.byType(ListTile),
      );
      expect(
        find.descendant(
          of: card,
          matching: find.byIcon(
            task.isCompleted
                ? Icons.radio_button_unchecked
                : Icons.check_circle,
          ),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text(task.title));
      await tester.pumpAndSettle();
      expect(
        find.text(
          task.isCompleted ? 'Estado: pendiente' : 'Estado: completada',
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.text(
          task.isCompleted ? 'Marcar como completada' : 'Marcar como pendiente',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          task.isCompleted ? 'Estado: completada' : 'Estado: pendiente',
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Volver al listado'));
      await tester.tap(find.text('Volver al listado'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Muestra un aviso si el id es inválido o no existe', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    for (final id in ['abc', '999']) {
      appRouter.go('/task/$id');
      await tester.pumpAndSettle();
      expect(find.text('No se encontró esta tarea.'), findsOneWidget);

      await tester.ensureVisible(find.text('Volver al listado'));
      await tester.tap(find.text('Volver al listado'));
      await tester.pumpAndSettle();
      expect(find.text('Mis tareas'), findsOneWidget);
    }
  });

  testWidgets('Muestra el panel inicial personalizado', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
    expect(find.text('TaskFlow'), findsOneWidget);
    expect(find.text('¡Hola, Héctor!'), findsOneWidget);
    expect(
      find.text('¡Organiza tus tareas y alcanza tus metas!'),
      findsOneWidget,
    );
    expect(find.text('Tareas pendientes: 3'), findsOneWidget);
    expect(find.text('Completadas hoy: 0 de 5'), findsOneWidget);
    expect(find.text('Aún tienes tareas por organizar.'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('Agrega, completa y reactiva tareas sin superar la meta', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Agregar tarea'));
      await tester.pump();
    }
    expect(find.text('Tareas pendientes: 5'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Completar una tarea'));
      await tester.pump();
    }
    expect(find.text('Tareas pendientes: 0'), findsOneWidget);
    expect(find.text('Completadas hoy: 5 de 5'), findsOneWidget);
    expect(
      find.text('¡Excelente! No tienes tareas pendientes.'),
      findsOneWidget,
    );
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
    await tester.tap(find.text('Completar una tarea'));
    await tester.pump();
    expect(find.text('Tareas pendientes: 0'), findsOneWidget);
    await tester.tap(find.text('Agregar tarea'));
    await tester.pump();
    expect(find.text('Tareas pendientes: 1'), findsOneWidget);
    expect(find.text('Aún tienes tareas por organizar.'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNotNull,
    );
    await tester.tap(find.text('Completar una tarea'));
    await tester.pump();
    expect(find.text('Tareas pendientes: 0'), findsOneWidget);
    expect(find.text('Completadas hoy: 5 de 5'), findsOneWidget);
  });
}
