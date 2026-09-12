import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:stacktask_mobile/src/core/state/json_serializable.dart';

class StateService {
  final SharedPreferences? _prefs;
  final Map<Type, Object> _values = {};
  final Map<Type, JsonSerializable Function(Map<String, dynamic>)> _decoders =
      {};

  StateService(SharedPreferences? prefs) : _prefs = prefs;

  void register<T extends JsonSerializable>(
    JsonSerializable Function(Map<String, dynamic>) fromJson,
  ) {
    _decoders[T] = fromJson;
  }

  Future<void> load() async {
    final prefs = _prefs;
    if (prefs == null) return;
    for (final entry in _decoders.entries) {
      final raw = prefs.getString(_keyForType(entry.key));
      if (raw == null) continue;
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _values[entry.key] = entry.value(json);
      } catch (_) {
        // Corrupted value — ignore and fall back to defaults.
      }
    }
  }

  T? get<T extends JsonSerializable>() => _values[T] as T?;

  Future<void> save<T extends JsonSerializable>(T value) async {
    _values[T] = value;
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(_keyForType(T), jsonEncode(value.toJson()));
  }

  String _keyForType(Type type) => 'state::${type.toString()}';
}
