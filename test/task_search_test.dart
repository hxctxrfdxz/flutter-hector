import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taskflow/features/tasks/domain/task.dart';
import 'package:taskflow/features/tasks/presentation/task_list_screen.dart';
import 'package:taskflow/features/tasks/presentation/tasks_view_model.dart';

import 'fake_task_repository.dart';

const tasks = [
  Task(
    id: 21,
    title: 'Preparar entrega',
    description: 'Revisar las evidencias.',
    priority: 'Alta',
    isCompleted: false,
    userId: 2,
  ),
  Task(
    id: 22,
    title: 'Preparar demo',
    description: 'Probar la navegación.',
    priority: 'Media',
    isCompleted: true,
    userId: 2,
  ),
  Task(
    id: 23,
    title: 'Revisar código',
    description: 'Ejecutar las pruebas.',
    priority: 'Baja',
    isCompleted: false,
    userId: 2,
  ),
];

class CountingTaskRepository extends FakeTaskRepository {
  CountingTaskRepository() : super(tasks);

  int loads = 0;

  @override
  Future<List<Task>> getTasks() {
    loads++;
    return super.getTasks();
  }
}

void main() {
  test(
    'Combina texto y estado sin alterar datos ni repetir la consulta',
    () async {
      final repository = CountingTaskRepository();
      final model = TasksViewModel(repository);
      addTearDown(model.dispose);
      await model.loadTasks();

      model.setQuery('  PREPARAR  ');
      expect(model.visibleTasks.map((task) => task.id), [21, 22]);
      model.setOnlyPending(true);
      expect(model.visibleTasks.map((task) => task.id), [21]);
      model.toggleCompleted(21);
      expect(model.visibleTasks, isEmpty);
      expect(model.tasks, hasLength(3));
      expect(model.isEmpty, isFalse);

      model.clearFilters();
      expect(model.query, isEmpty);
      expect(model.onlyPending, isFalse);
      expect(model.visibleTasks, hasLength(3));
      expect(repository.loads, 1);
      expect(repository.items, hasLength(3));
    },
  );

  testWidgets(
    'Busca, combina filtros, muestra cero resultados y limpia el campo',
    (tester) async {
      final repository = CountingTaskRepository();
      final model = TasksViewModel(repository);
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => model..loadTasks(),
          child: const MaterialApp(home: TaskListScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'PREPARAR');
      await tester.pumpAndSettle();
      expect(find.text('Preparar entrega'), findsOneWidget);
      expect(find.text('Preparar demo'), findsOneWidget);
      expect(find.text('Revisar código'), findsNothing);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(find.text('Preparar entrega'), findsOneWidget);
      expect(find.text('Preparar demo'), findsNothing);

      await tester.enterText(find.byType(TextField), 'sin coincidencias');
      await tester.pumpAndSettle();
      expect(
        find.text('No hay resultados para estos filtros.'),
        findsOneWidget,
      );
      expect(find.text('Todavía no hay tareas para mostrar.'), findsNothing);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );

      await tester.tap(find.text('Limpiar filtros'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
      expect(find.text('Preparar demo'), findsOneWidget);
      expect(repository.loads, 1);
      expect(model.tasks, hasLength(3));
    },
  );

  testWidgets('Mantiene controles y estados accesibles con texto grande', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TasksViewModel(FakeTaskRepository(tasks))..loadTasks(),
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const TaskListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Actualizar tareas'), findsOneWidget);
    expect(find.byTooltip('Configuración'), findsOneWidget);
    expect(find.text('Limpiar filtros'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Icon && widget.semanticLabel == 'Tarea pendiente',
      ),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });
}
