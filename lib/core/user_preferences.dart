import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  UserPreferences(this._preferences);

  final SharedPreferencesAsync _preferences;
  static const _nameKey = 'user_name';

  Future<String> readName() async =>
      await _preferences.getString(_nameKey) ?? 'Estudiante';

  Future<void> saveName(String name) async {
    await _preferences.setString(_nameKey, name.trim());
  }
}
