import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/main.dart';

void main() {
  testWidgets('Muestra el panel inicial personalizado', (tester) async {
    await tester.pumpWidget(const TaskFlowApp());
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
    await tester.pumpWidget(const TaskFlowApp());
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
