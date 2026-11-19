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

## Estados de la lista y reintento

En la sesión 8, la lista distingue carga, tareas disponibles, respuesta vacía
y error. La acción «Actualizar tareas» de la barra y el gesto de deslizar hacia
abajo repiten la consulta. Mientras hay una petición activa, el botón queda
deshabilitado y el ViewModel evita iniciar otra consulta simultánea.

Para comprobar cada estado en Chrome con `flutter run -d chrome`, seguir este
procedimiento.

| Estado | Cómo provocarlo | Resultado esperado |
| --- | --- | --- |
| Datos disponibles | Mantener internet activo y `TaskApiService.userId = 2`, iniciar la app o pulsar «Actualizar tareas». | Aparecen las tareas remotas y cada tarjeta abre su detalle. |
| Carga | En DevTools de Chrome, abrir Network, seleccionar Slow 3G y pulsar «Actualizar tareas». | Aparece el indicador de progreso y se deshabilita el botón de actualización. Al finalizar se presenta la respuesta. |
| Error | Con DevTools abierto, seleccionar Offline en Network y pulsar «Actualizar tareas». | Aparece «No se pudieron cargar las tareas.» junto a «Reintentar». |
| Recuperación | Tras el error, cambiar Offline a No throttling y pulsar «Reintentar». | Las tareas vuelven sin reiniciar TaskFlow. |
| Vacío | Cambiar temporalmente `TaskApiService.userId` a `9999` y hacer Hot Restart. | La API devuelve una lista vacía y aparecen «Todavía no hay tareas para mostrar.» y «Actualizar». |

Al terminar la comprobación de vacío, restaurar `userId = 2`, hacer Hot Restart
y dejar Network en No throttling. Para la evidencia se necesitan capturas del
listado, del vacío y del error, además de comprobar la recuperación con Reintentar.
Una respuesta vacía se considera válida. Un fallo limpia las tareas anteriores
y muestra el error. Actualizar vuelve a leer el servidor y recupera sus estados
originales para las tareas marcadas localmente.

## Formulario de tareas

La sesión 9 incorpora «Nueva tarea», accesible desde el botón del listado y la
ruta `/new`. El formulario prepara un `TaskDraft` con título, descripción,
prioridad y fecha opcional.

- El título es obligatorio y necesita al menos tres caracteres después de
  quitar espacios al principio y al final.
- La descripción es opcional.
- La prioridad permite Alta, Media o Baja, con Media seleccionada al abrir.
- «Elegir fecha (opcional)» abre el calendario. «Quitar fecha» permite retirarla.
- Guardar un formulario válido regresa al listado y muestra
  «Formulario válido» seguido del título ingresado.
- Cancelar o usar la flecha de regreso descarta el borrador sin mostrar ese aviso.

En esta sesión Guardar devuelve el borrador a la pantalla anterior. El listado
continúa mostrando las tareas consultadas desde la API. La conexión del guardado
con POST se implementará en la sesión 10.

Para comprobarlo, intentar guardar con un título vacío, uno de dos caracteres y
uno válido. Verificar el guardado con y sin fecha, la selección de prioridad,
la cancelación y el acceso al detalle de las tareas existentes.
La evidencia de la sesión incluye capturas de errores de validación, formulario
válido y mensaje de retorno al listado.

## CRUD de tareas

Desde la sesión 10, Guardar prepara el borrador y el listado lo envía mediante
`POST /todos`. La tarea aparece después de recibir una respuesta correcta,
con el mensaje «Tarea creada». El título y la descripción se envían al repositorio
junto con la prioridad. El servicio envía a la API título, estado y usuario.
Descripción y prioridad se conservan en memoria.

En el detalle, «Editar título» abre un diálogo con el título actual.
El nuevo título necesita al menos tres caracteres. Guardar envía
`PATCH /todos/:id` con título y estado. Si la respuesta es correcta, lista y
detalle muestran el nuevo título y aparece «Tarea actualizada».

«Eliminar tarea» pide confirmación. Cancelar conserva la tarea.
Confirmar envía `DELETE /todos/:id`; tras una respuesta correcta, la tarea
desaparece y se regresa al listado con «Tarea eliminada».
Una operación fallida muestra su mensaje de error y conserva los datos anteriores.

JSONPlaceholder simula las escrituras. Al actualizar la lista o reiniciar,
vuelven los datos originales. Los títulos creados y editados no se guardan
permanentemente. Para comprobar edición, usar una tarea recibida por GET:
un id devuelto por POST puede no existir en el servidor para un PATCH posterior.
Si POST repite un identificador ya usado, el repositorio asigna el siguiente
id libre en la copia en memoria para distinguir las nuevas tarjetas.

La fecha opcional forma parte del borrador del formulario de la sesión 9.
El contrato de creación de esta práctica conserva título, descripción y prioridad.
El cambio con «Marcar como completada/pendiente» mantiene su comportamiento local.

Para la evidencia, tomar capturas antes y después de crear una tarea, editar
el título de una tarea existente y confirmar su eliminación. Comprobar también
la cancelación y un fallo de red: el error debe mostrar el aviso correspondiente.
