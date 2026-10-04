import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/user_entity.dart';

class AuthLocalDatasource {
  final AppDatabase _db;
  AuthLocalDatasource(this._db);

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<UserEntity?> login(String username, String password) async {
    final hash = _hashPassword(password);
    final user = await (_db.select(_db.users)
          ..where((u) =>
              u.username.equals(username) &
              u.passwordHash.equals(hash) &
              u.isActive.equals(true)))
        .getSingleOrNull();

    if (user == null) return null;

    // تحديث وقت آخر دخول
    await (_db.update(_db.users)..where((u) => u.id.equals(user.id)))
        .write(UsersCompanion(lastLoginAt: Value(DateTime.now())));

    return UserEntity(
      id: user.id,
      username: user.username,
      fullName: user.fullName,
      role: user.role,
      isActive: user.isActive,
    );
  }

  Future<List<UserEntity>> getAllUsers() async {
    final rows = await _db.select(_db.users).get();
    return rows
        .map((u) => UserEntity(
              id: u.id,
              username: u.username,
              fullName: u.fullName,
              role: u.role,
              isActive: u.isActive,
            ))
        .toList();
  }

  Future<void> createUser({
    required String username,
    required String password,
    required String fullName,
    required String role,
  }) async {
    await _db.into(_db.users).insert(UsersCompanion.insert(
          username: username,
          passwordHash: _hashPassword(password),
          fullName: fullName,
          role: role,
        ));
  }

  Future<void> updateUser({
    required int id,
    required String fullName,
    required String role,
    required bool isActive,
  }) async {
    await (_db.update(_db.users)..where((u) => u.id.equals(id))).write(
      UsersCompanion(
        fullName: Value(fullName),
        role: Value(role),
        isActive: Value(isActive),
      ),
    );
  }

  Future<bool> changePassword(
      int userId, String oldPassword, String newPassword) async {
    final oldHash = _hashPassword(oldPassword);
    final user = await (_db.select(_db.users)
          ..where(
              (u) => u.id.equals(userId) & u.passwordHash.equals(oldHash)))
        .getSingleOrNull();

    if (user == null) return false;

    await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(passwordHash: Value(_hashPassword(newPassword))),
    );
    return true;
  }
}
