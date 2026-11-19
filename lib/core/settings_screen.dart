import 'package:flutter/material.dart';

import 'user_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.preferences});

  final UserPreferences preferences;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final name = await widget.preferences.readName();
      if (!mounted) return;
      _controller.text = name;
    } catch (error) {
      debugPrint('Error al leer el nombre: $error');
      _loadError = 'No se pudo recuperar tu nombre.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.preferences.saveName(_controller.text);
      if (!mounted) return;
      _controller.text = _controller.text.trim();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nombre guardado')));
    } catch (error) {
      debugPrint('Error al guardar el nombre: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar tu nombre.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_loadError!),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _load,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _controller,
                    enabled: !_saving,
                    decoration: const InputDecoration(labelText: 'Tu nombre'),
                    validator: (value) => (value?.trim() ?? '').isEmpty
                        ? 'Escribe tu nombre.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Guardando...' : 'Guardar'),
                  ),
                ],
              ),
            ),
    );
  }
}
