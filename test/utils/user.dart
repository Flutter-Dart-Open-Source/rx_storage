import 'dart:convert';

import 'package:rx_storage/rx_storage.dart';

class User {
  final int id;
  final String name;

  const User(this.id, this.name);

  factory User.fromJson(Map<String, Object?> map) {
    return User(
      map['id'] as int,
      map['name'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
    };
  }

  User withName(String name) => User(id, name);

  @override
  String toString() => 'User{id: $id, name: $name}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

extension RxStoreageExtensionsForUser on RxStorage<String, void> {
  Future<User?> readUser() => read('User', jsonStringToUser);

  Future<void> writeUser(User? user) =>
      write<User>('User', user, userToJsonString);

  Stream<User?> observeUser() => observe<User>('User', jsonStringToUser);
}

Future<User?> jsonStringToUser(Object? s) async {
  await Future<void>.delayed(const Duration(milliseconds: 10));

  if (s == null) {
    return null;
  }
  final map = jsonDecode(s as String) as Map<String, Object?>;
  return User.fromJson(map);
}

String? userToJsonString(User? u) => u == null ? null : jsonEncode(u);
