# taskflow

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Alcance de TaskFlow

**Problema.** Las actividades académicas y sus entregas pueden quedar dispersas
entre apuntes y mensajes. TaskFlow reúne los pendientes y las tareas completadas
en una sola lista para facilitar la planificación semanal.

**Usuario objetivo.** Estudiantes que organizan sus actividades y entregas
académicas.

En la sesión 5, la app muestra un listado local de cinco tareas del proyecto y
permite consultar su detalle. El alcance final incluye crear, editar y eliminar
tareas en sesiones posteriores.

### Historias de usuario y criterios de aceptación

| Historia de usuario | Criterio de aceptación |
| --- | --- |
| Como estudiante, quiero listar mis tareas para identificar qué me falta. | Cada tarjeta muestra el título, la prioridad y un icono que distingue entre pendiente y completada. |
| Como estudiante, quiero consultar el detalle de una tarea para saber qué debo hacer. | Al tocar una tarjeta se abre su descripción completa, prioridad, estado e identificador de usuario. |
| Como estudiante, quiero crear una tarea para registrar un nuevo pendiente. | Al guardar un formulario válido, aparece una nueva tarea pendiente en la lista. |
| Como estudiante, quiero editar una tarea para corregir sus datos o actualizar su estado. | Al guardar cambios, la lista y el detalle muestran los datos actualizados. |
| Como estudiante, quiero eliminar una tarea que ya no necesito para mantener mi lista al día. | Al confirmar la eliminación, la tarea desaparece de la lista. Si cancelo, permanece. |

### Modelo de datos y contrato JSON

| Campo de `Task` y clave JSON | Tipo Dart | Significado |
| --- | --- | --- |
| `id` | `int` | Identificador único de la tarea. |
| `title` | `String` | Título breve para el listado. |
| `description` | `String` | Descripción completa de la actividad. |
| `priority` | `String` | Alta, Media o Baja. |
| `isCompleted` | `bool` | `true` indica completada y `false` indica pendiente. |
| `userId` | `int` | Identificador del usuario propietario. Los datos locales usan el usuario de prueba 1. |

`Task.fromJson` acepta el formato local con seis campos y el formato remoto
descrito en «API de tareas».

### Boceto de pantallas

| Pantalla | Elementos de arriba hacia abajo |
| --- | --- |
| **Mis tareas** | Barra superior → tarjetas con título, prioridad y estado → futura acción «Nueva tarea». |
| **Detalle de tarea** | Barra con flecha de regreso → título, descripción, prioridad, estado y usuario → «Consultar estado» y «Volver al listado». Más adelante incluirá acciones para editar y eliminar. |
| **Formulario futuro** | Título «Nueva tarea» o «Editar tarea» → campos de título, descripción y prioridad → botón «Guardar». |

### Requisitos no funcionales

- Las pantallas y los controles deben tener nombres claros en español.
- Un identificador inválido o inexistente debe mostrar un mensaje y permitir
  volver al listado.

### Operaciones previstas de la API

| Método y ruta previstos | Operación |
| --- | --- |
| `GET /tasks` | Listar tareas. |
| `GET /tasks/:id` | Consultar una tarea. |
| `POST /tasks` | Crear una tarea. |
| `PATCH /tasks/:id` | Actualizar los campos que cambiaron. |
| `DELETE /tasks/:id` | Eliminar una tarea. |

La API se elegirá en una sesión posterior. En la sesión 5 se usan datos locales.

## API de tareas

Desde la sesión 7, TaskFlow obtiene tareas de JSONPlaceholder usando Dio.
La URL exacta elegida para esta práctica es
[https://jsonplaceholder.typicode.com/todos?userId=2](https://jsonplaceholder.typicode.com/todos?userId=2).
La constante `TaskApiService.userId = 2` selecciona las tareas del usuario 2
como adaptación del ejemplo guiado, que usa el usuario 1.

| Campo recibido | Campo de TaskFlow |
| --- | --- |
| `id` | `id`, identificador de la tarea. |
| `title` | `title`, título que aparece en lista y detalle. |
| `completed` | `isCompleted`, estado pendiente o completada. |
| `userId` | `userId`, identificador del propietario. |

La API entrega esos cuatro campos. TaskFlow completa `description` con
«Sin descripción (API)» y `priority` con «Sin prioridad (API)» cuando faltan.
Estos textos son valores predeterminados de la aplicación.

`TaskApiService` conoce la URL y realiza el GET. `Task.fromJson` convierte cada
objeto JSON en una tarea. `RemoteTaskRepository` conserva una copia en memoria.
`TasksViewModel.loadTasks` espera la respuesta y notifica a las vistas mediante
Provider. La consola registra `GET /todos?userId=2 → HTTP 200` cuando la consulta
termina correctamente. Durante la espera se muestra un indicador de carga y,
si falla, «No se pudieron cargar las tareas.».

Marcar una tarea como completada o pendiente modifica la copia local en memoria.
Al reiniciar la app o volver a cargar desde la API se recuperan los valores del
servidor. La sesión 7 realiza consultas GET. Las operaciones de escritura remota
se trabajarán en sesiones posteriores.

Las cinco tareas propias de la sesión 6 siguen en `LocalTaskRepository`, que
también implementa el contrato asíncrono `Future<List<Task>>`.
