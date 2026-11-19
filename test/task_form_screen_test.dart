import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:taskflow/app/taskflow_app.dart';
import 'package:taskflow/features/tasks/data/local_task_repository.dart';
import 'package:taskflow/features/tasks/presentation/task_form_screen.dart';
import 'package:taskflow/features/tasks/presentation/tasks_view_model.dart';

Widget buildTestApp() {
  appRouter.go('/');
  return ChangeNotifierProvider(
    create: (_) => TasksViewModel(LocalTaskRepository())..loadTasks(),
    child: const TaskFlowApp(),
  );
}

void main() {
  testWidgets('Valida el título y crea una tarea sin fecha desde el listado', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva tarea'));
    await tester.pumpAndSettle();
    expect(appRouter.state.uri.path, '/new');

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe el título de tu tarea.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '  ab  ');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(
      find.text('El título debe tener al menos 3 caracteres.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byType(TextFormField).first,
      '  Preparar demo  ',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(appRouter.state.uri.path, '/');
    expect(find.text('Tarea creada'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Preparar demo'), 150);
    expect(find.widgetWithText(ListTile, 'Preparar demo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cancelar y regresar descartan el formulario sin confirmación', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    for (final cancelWithButton in [true, false]) {
      await tester.tap(find.text('Nueva tarea'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Descartar tarea',
      );
      if (cancelWithButton) {
        await tester.tap(find.text('Cancelar'));
      } else {
        await tester.pageBack();
      }
      await tester.pumpAndSettle();
      expect(appRouter.state.uri.path, '/');
      expect(find.byType(SnackBar), findsNothing);
    }
  });

  testWidgets('Incluye descripción, prioridad y fecha elegida en el borrador', (
    tester,
  ) async {
    TaskDraft? result;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await context.push<TaskDraft>('/new');
              },
              child: const Text('Abrir formulario'),
            ),
          ),
        ),
        GoRoute(path: '/new', builder: (_, _) => const TaskFormScreen()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TasksViewModel(LocalTaskRepository()),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir formulario'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      '  Preparar demo  ',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      '  Revisar las capturas  ',
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alta').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Elegir fecha (opcional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15').last);
    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Quitar fecha'), findsOneWidget);

    await tester.tap(find.byTooltip('Quitar fecha'));
    await tester.pumpAndSettle();
    expect(find.text('Elegir fecha (opcional)'), findsOneWidget);

    await tester.tap(find.text('Elegir fecha (opcional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15').last);
    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.title, 'Preparar demo');
    expect(result!.description, 'Revisar las capturas');
    expect(result!.priority, 'Alta');
    expect(result!.dueDate!.day, 15);
    expect(find.text('Abrir formulario'), findsOneWidget);
  });
}
