import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDatasource _datasource;
  SettingsRepositoryImpl(this._datasource);

  @override
  Future<ShopSettingsEntity> getSettings() => _datasource.getSettings();

  @override
  Future<bool> updateSettings(ShopSettingsEntity settings) => _datasource.updateSettings(settings);

  @override
  Future<String?> backupDatabase(String destinationDirectory) => _datasource.backupDatabase(destinationDirectory);

  @override
  Future<bool> restoreDatabase(String sourceFilePath) => _datasource.restoreDatabase(sourceFilePath);

  @override
  Future<bool> verifyAdminPassword(String password) => _datasource.verifyAdminPassword(password);

  @override
  Future<bool> factoryReset(String password) async {
    final valid = await _datasource.verifyAdminPassword(password);
    if (!valid) return false;
    await _datasource.factoryReset();
    return true;
  }
}

