import 'package:stacktask_mobile/src/core/state/json_serializable.dart';

class MainState implements JsonSerializable {
  final String? group;

  const MainState({this.group});

  @override
  Map<String, dynamic> toJson() => {'group': group};

  factory MainState.fromJson(Map<String, dynamic> json) =>
      MainState(group: json['group'] as String?);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MainState && group == other.group;

  @override
  int get hashCode => group.hashCode;
}
