import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskflow/core/settings_screen.dart';
import 'package:taskflow/core/user_preferences.dart';

class FakePreferences implements SharedPreferencesAsync {
  final values = <String, String>{};
  final failures = <String>{};

  @override
  Future<String?> getString(String key) async {
    if (failures.contains('read')) throw StateError('Lectura fallida');
    return values[key];
  }

  @override
  Future<void> setString(String key, String value) async {
    if (failures.contains('write')) throw StateError('Guardado fallido');
    values[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'Usa el nombre inicial y recupera el nombre guardado sin espacios',
    () async {
      final storage = FakePreferences();
      final preferences = UserPreferences(storage);
      expect(await preferences.readName(), 'Estudiante');
      await preferences.saveName('  Héctor  ');
      expect(storage.values['user_name'], 'Héctor');
      expect(await UserPreferences(storage).readName(), 'Héctor');
    },
  );

  testWidgets('Valida el nombre y lo recupera al volver a crear la pantalla', (
    tester,
  ) async {
    final storage = FakePreferences();
    Widget settings() => MaterialApp(
      home: SettingsScreen(preferences: UserPreferences(storage)),
    );
    await tester.pumpWidget(settings());
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Estudiante'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe tu nombre.'), findsOneWidget);
    expect(storage.values, isEmpty);

    await tester.enterText(find.byType(TextFormField), '  Héctor  ');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Nombre guardado'), findsOneWidget);
    expect(storage.values['user_name'], 'Héctor');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(settings());
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Héctor'), findsOneWidget);
  });

  testWidgets(
    'Permite recuperar una lectura fallida y conserva el nombre si no puede guardarlo',
    (tester) async {
      final storage = FakePreferences()..failures.add('read');
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(preferences: UserPreferences(storage)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No se pudo recuperar tu nombre.'), findsOneWidget);
      storage.failures.remove('read');
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Héctor');
      storage.failures.add('write');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('No se pudo guardar tu nombre.'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Héctor'), findsOneWidget);
      expect(storage.values, isEmpty);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    },
  );
}
