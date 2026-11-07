import 'package:flutter/material.dart';

void main() {
  runApp(const TaskFlowApp());
}

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TaskFlow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const TaskListScreen(),
    );
  }
}

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.isCompleted,
  });

  final int id;
  final String title;
  final String description;
  final String priority;
  final bool isCompleted;
}

const demoTasks = [
  Task(
    id: 1,
    title: 'Crear la bienvenida de TaskFlow',
    description: 'Mostrar el nombre del estudiante y el mensaje de bienvenida.',
    priority: 'Alta',
    isCompleted: true,
  ),
  Task(
    id: 2,
    title: 'Agregar el contador interactivo',
    description:
        'Agregar y completar tareas con setState y un objetivo diario.',
    priority: 'Alta',
    isCompleted: true,
  ),
  Task(
    id: 3,
    title: 'Construir el listado local',
    description: 'Representar cinco tareas con ListView.builder y TaskCard.',
    priority: 'Alta',
    isCompleted: false,
  ),
  Task(
    id: 4,
    title: 'Verificar las tarjetas de tareas',
    description:
        'Revisar la prioridad, el estado y el desplazamiento de la lista.',
    priority: 'Media',
    isCompleted: false,
  ),
  Task(
    id: 5,
    title: 'Guardar la evidencia de la sesión 3',
    description: 'Capturar el listado y una tarea completada para la entrega.',
    priority: 'Baja',
    isCompleted: false,
  ),
];

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: task.isCompleted ? Colors.green : null,
        ),
        title: Text(task.title),
        subtitle: Text('${task.priority} · ${task.description}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis tareas')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: demoTasks.length,
        itemBuilder: (context, index) {
          final task = demoTasks[index];
          return TaskCard(task: task);
        },
      ),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final String studentName = 'Héctor';
  static const dailyGoal = 5;
  int pendingTasks = 3;
  int completedTasks = 0;

  void _addTask() {
    setState(() {
      pendingTasks++;
    });
  }

  void _completeTask() {
    if (pendingTasks == 0) return;

    setState(() {
      pendingTasks--;
      if (completedTasks < dailyGoal) {
        completedTasks++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Variables de la aplicación
    const courseName = 'Desarrollo de aplicaciones móviles';
    const motivationalMessage = '¡Organiza tus tareas y alcanza tus metas!';
    final statusMessage = pendingTasks == 0
        ? '¡Excelente! No tienes tareas pendientes.'
        : 'Aún tienes tareas por organizar.';

    return Scaffold(
      appBar: AppBar(title: const Text('TaskFlow'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono de la aplicación
            const Icon(Icons.task_alt, size: 56, color: Colors.indigo),

            const SizedBox(height: 24),

            // Saludo personalizado
            Text(
              '¡Hola, $studentName!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 12),

            // Mensaje motivacional
            const Text(
              motivationalMessage,
              style: TextStyle(fontSize: 16, color: Colors.indigo),
            ),

            const SizedBox(height: 12),

            // Nombre de la materia
            const Text('Bienvenido/a a $courseName.'),

            const SizedBox(height: 32),

            Text(statusMessage),
            Text('Completadas hoy: $completedTasks de $dailyGoal'),
            const SizedBox(height: 12),

            // Tarjeta de tareas pendientes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.pending_actions),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Tareas pendientes: $pendingTasks')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _addTask,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar tarea'),
                ),
                OutlinedButton.icon(
                  onPressed: pendingTasks == 0 ? null : _completeTask,
                  icon: const Icon(Icons.done),
                  label: const Text('Completar una tarea'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
