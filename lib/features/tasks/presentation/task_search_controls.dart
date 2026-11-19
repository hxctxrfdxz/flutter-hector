import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'tasks_view_model.dart';

class TaskSearchControls extends StatefulWidget {
  const TaskSearchControls({super.key});

  @override
  State<TaskSearchControls> createState() => _TaskSearchControlsState();
}

class _TaskSearchControlsState extends State<TaskSearchControls> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: context.read<TasksViewModel>().query);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<TasksViewModel>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              labelText: 'Buscar por título',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: context.read<TasksViewModel>().setQuery,
          ),
          SwitchListTile(
            title: const Text('Solo pendientes'),
            value: model.onlyPending,
            onChanged: context.read<TasksViewModel>().setOnlyPending,
          ),
          TextButton(
            onPressed: () {
              _search.clear();
              context.read<TasksViewModel>().clearFilters();
            },
            child: const Text('Limpiar filtros'),
          ),
        ],
      ),
    );
  }
}
