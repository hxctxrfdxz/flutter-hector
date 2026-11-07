import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/main.dart';

void main() {
  testWidgets('El listado muestra tareas locales y permite desplazarse', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TaskFlowApp());
    await tester.pumpAndSettle();
    expect(find.text('Mis tareas'), findsOneWidget);
    expect(find.text('Crear la bienvenida de TaskFlow'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsWidgets);
    expect(find.byIcon(Icons.chevron_right), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Guardar la evidencia de la sesión 3'),
      150,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Guardar la evidencia de la sesión 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Abre tres tareas por id y vuelve al listado', (tester) async {
    appRouter.go('/');
    await tester.pumpWidget(const TaskFlowApp());
    await tester.pumpAndSettle();

    for (final task in demoTasks.take(3)) {
      await tester.tap(find.text(task.title));
      await tester.pumpAndSettle();

      expect(find.text('Detalle de tarea'), findsOneWidget);
      expect(find.text(task.title), findsOneWidget);
      expect(find.text(task.description), findsOneWidget);
      expect(find.text('Prioridad: ${task.priority}'), findsOneWidget);
      expect(
        find.text(
          task.isCompleted ? 'Estado: completada' : 'Estado: pendiente',
        ),
        findsOneWidget,
      );
      expect(appRouter.state.uri.path, '/task/${task.id}');

      await tester.tap(find.text('Consultar estado'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          task.isCompleted
              ? 'Esta tarea ya está completada.'
              : 'Esta tarea está pendiente.',
        ),
        findsOneWidget,
      );
      // Esperar a que termine el aviso antes de cambiar de pantalla.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      if (task.id == 2) {
        await tester.pageBack();
      } else {
        await tester.tap(find.text('Volver al listado'));
      }
      await tester.pumpAndSettle();
      expect(find.text('Mis tareas'), findsOneWidget);
      expect(appRouter.state.uri.path, '/');
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
