import '../entities/settings_entity.dart';

abstract class SettingsRepository {
  Future<ShopSettingsEntity> getSettings();
  Future<bool> updateSettings(ShopSettingsEntity settings);
  Future<String?> backupDatabase(String destinationDirectory);
  Future<bool> restoreDatabase(String sourceFilePath);
  Future<bool> verifyAdminPassword(String password);
  Future<bool> factoryReset(String password);
}

