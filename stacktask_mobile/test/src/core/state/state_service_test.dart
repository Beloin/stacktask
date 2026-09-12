import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stacktask_mobile/src/core/state/main_state.dart';
import 'package:stacktask_mobile/src/core/state/state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<StateService> makeService() async {
    final prefs = await SharedPreferences.getInstance();
    final service = StateService(prefs);
    service.register<MainState>(MainState.fromJson);
    return service;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('get returns null before save', () async {
    final service = await makeService();
    expect(service.get<MainState>(), isNull);
  });

  test('save and get round-trip', () async {
    final service = await makeService();
    await service.save<MainState>(const MainState(group: 'g-1'));
    expect(service.get<MainState>()?.group, 'g-1');
  });

  test('load hydrates a previously saved value', () async {
    final service = await makeService();
    await service.save<MainState>(const MainState(group: 'g-2'));

    final restored = await makeService();
    await restored.load();
    expect(restored.get<MainState>()?.group, 'g-2');
  });

  test('load skips missing keys', () async {
    final service = await makeService();
    await service.load();
    expect(service.get<MainState>(), isNull);
  });

  test('load reconstructs via registered fromJson', () async {
    SharedPreferences.setMockInitialValues({
      'state::MainState': '{"group":"g-3"}',
    });
    final service = await makeService();
    await service.load();
    expect(service.get<MainState>()?.group, 'g-3');
  });

  test('save overwrites previous value', () async {
    final service = await makeService();
    await service.save<MainState>(const MainState(group: 'first'));
    await service.save<MainState>(const MainState(group: 'second'));
    expect(service.get<MainState>()?.group, 'second');
  });

  test('survives a fresh service backed by the same prefs (simulates relaunch)',
      () async {
    final prefs1 = await SharedPreferences.getInstance();
    final service1 = StateService(prefs1);
    service1.register<MainState>(MainState.fromJson);
    await service1.save<MainState>(const MainState(group: 'g-restored'));

    // New service, same prefs — simulates a relaunch.
    final prefs2 = await SharedPreferences.getInstance();
    final service2 = StateService(prefs2);
    service2.register<MainState>(MainState.fromJson);
    await service2.load();

    expect(service2.get<MainState>()?.group, 'g-restored');
  });
}
