import 'package:sqflite/sqflite.dart';

abstract class Migration {
  const Migration();

  int get version;

  String get description;

  Future<void> up(Database db);
}
