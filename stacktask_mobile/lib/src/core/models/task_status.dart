enum TaskStatus {
  doing,
  done,
  ignored;

  static TaskStatus fromName(String? name) {
    if (name == null) return TaskStatus.doing;
    return TaskStatus.values.firstWhere(
      (s) => s.name == name,
      orElse: () => TaskStatus.doing,
    );
  }
}