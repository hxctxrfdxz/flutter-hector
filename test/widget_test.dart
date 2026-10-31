
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/main.dart';

void main() {
  testWidgets('Verificar pantalla de bienvenida de TaskFlow',
      (WidgetTester tester) async {

    // Iniciar la aplicación
    await tester.pumpWidget(const TaskFlowApp());

    // Verificar que aparece el título
    expect(find.text('TaskFlow'), findsOneWidget);

    // Verificar el saludo
    expect(find.text('¡Hola, Héctor!'), findsOneWidget);

    // Verificar el mensaje motivacional
    expect(
      find.text('¡Organiza tus tareas y alcanza tus metas!'),
      findsOneWidget,
    );

    // Verificar las tareas pendientes
    expect(
      find.text('Tareas pendientes: 334'),
      findsOneWidget,
    );
  });
}
