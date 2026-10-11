import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/settings_entity.dart';

class SettingsLocalDatasource {
  final AppDatabase _db;
  SettingsLocalDatasource(this._db);

  Future<ShopSettingsEntity> getSettings() async {
    final rows = await _db.select(_db.appSettings).get();
    final Map<String, String> map = {for (final r in rows) r.key: r.value};

    return ShopSettingsEntity(
      shopName: map['shop_name'] ?? 'Screena Shop',
      shopAddress: map['shop_address'] ?? '',
      shopPhone: map['shop_phone'] ?? '',
      currency: map['currency'] ?? 'ج',
      currencyDecimals: int.tryParse(map['currency_decimals'] ?? '2') ?? 2,
      allowNegativeStock: (map['allow_negative_stock'] ?? 'false') == 'true',
      lowStockThreshold: double.tryParse(map['low_stock_threshold'] ?? '10') ?? 10.0,
      invoiceFooter: map['invoice_footer'] ?? 'شكراً لتعاملكم معنا',
      taxRate: double.tryParse(map['tax_rate'] ?? '0') ?? 0.0,
      taxEnabled: (map['tax_enabled'] ?? 'false') == 'true',
      backupPath: map['backup_path'] ?? '',
    );
  }

  Future<bool> updateSettings(ShopSettingsEntity s) async {
    final Map<String, String> map = {
      'shop_name': s.shopName,
      'shop_address': s.shopAddress,
      'shop_phone': s.shopPhone,
      'currency': s.currency,
      'currency_decimals': s.currencyDecimals.toString(),
      'allow_negative_stock': s.allowNegativeStock.toString(),
      'low_stock_threshold': s.lowStockThreshold.toString(),
      'invoice_footer': s.invoiceFooter,
      'tax_rate': s.taxRate.toString(),
      'tax_enabled': s.taxEnabled.toString(),
      'backup_path': s.backupPath,
    };

    for (final entry in map.entries) {
      await _db.into(_db.appSettings).insertOnConflictUpdate(
            AppSettingsCompanion.insert(
              key: entry.key,
              value: entry.value,
            ),
          );
    }
    return true;
  }

  Future<String?> backupDatabase(String destinationDirectory) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(docDir.path, 'screena_shop.db'));

      if (!await dbFile.exists()) return null;

      final now = DateTime.now();
      final timestamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}';
      final backupFileName = 'screena_backup_$timestamp.db';
      final destPath = p.join(destinationDirectory, backupFileName);

      await dbFile.copy(destPath);
      return destPath;
    } catch (_) {
      return null;
    }
  }

  Future<bool> restoreDatabase(String sourceFilePath) async {
    try {
      final srcFile = File(sourceFilePath);
      if (!await srcFile.exists()) return false;

      final docDir = await getApplicationDocumentsDirectory();
      final targetPath = p.join(docDir.path, 'screena_shop.db');

      await _db.close();
      await srcFile.copy(targetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyAdminPassword(String password) => _db.verifyAdminPassword(password);

  Future<void> factoryReset() => _db.factoryReset();
}

