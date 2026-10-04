import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDatasource _datasource;
  AuthRepositoryImpl(this._datasource);

  @override
  Future<UserEntity?> login(String username, String password) =>
      _datasource.login(username, password);

  @override
  Future<void> logout() async {}

  @override
  Future<UserEntity?> getCurrentUser() async => null;

  @override
  Future<bool> changePassword(int userId, String oldPassword, String newPassword) =>
      _datasource.changePassword(userId, oldPassword, newPassword);
}
