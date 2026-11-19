import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app/taskflow_app.dart';
import 'features/tasks/data/local_task_repository.dart';
import 'features/tasks/data/task_repository.dart';
import 'features/tasks/presentation/tasks_view_model.dart';

void main() {
  GoRouter.optionURLReflectsImperativeAPIs = true;
  final TaskRepository repository = LocalTaskRepository();

  runApp(
    ChangeNotifierProvider<TasksViewModel>(
      create: (_) => TasksViewModel(repository),
      child: const TaskFlowApp(),
    ),
  );
}
