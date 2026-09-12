import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stacktask_mobile/app.dart';
import 'package:stacktask_mobile/src/core/state/main_state.dart';
import 'package:stacktask_mobile/src/core/state/state_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final stateService = await _createStateService();
  runApp(StackTasksApp(stateService: stateService));
}

Future<StateService> _createStateService() async {
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e, st) {
    debugPrint('SharedPreferences unavailable, starting without persistence: $e\n$st');
  }
  final stateService = StateService(prefs);
  if (prefs != null) {
    stateService.register<MainState>(MainState.fromJson);
    await stateService.load();
  }
  return stateService;
}
