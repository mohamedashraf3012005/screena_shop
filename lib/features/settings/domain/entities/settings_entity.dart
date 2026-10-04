import 'package:equatable/equatable.dart';

class ShopSettingsEntity extends Equatable {
  final String shopName;
  final String shopAddress;
  final String shopPhone;
  final String currency;
  final int currencyDecimals;
  final bool allowNegativeStock;
  final double lowStockThreshold;
  final String invoiceFooter;
  final double taxRate;
  final bool taxEnabled;
  final String backupPath;

  const ShopSettingsEntity({
    required this.shopName,
    required this.shopAddress,
    required this.shopPhone,
    required this.currency,
    required this.currencyDecimals,
    required this.allowNegativeStock,
    required this.lowStockThreshold,
    required this.invoiceFooter,
    required this.taxRate,
    required this.taxEnabled,
    required this.backupPath,
  });

  static const defaultSettings = ShopSettingsEntity(
    shopName: 'Screena Shop',
    shopAddress: '',
    shopPhone: '',
    currency: 'ج',
    currencyDecimals: 2,
    allowNegativeStock: false,
    lowStockThreshold: 10.0,
    invoiceFooter: 'شكراً لتعاملكم معنا',
    taxRate: 0.0,
    taxEnabled: false,
    backupPath: '',
  );

  @override
  List<Object?> get props => [
        shopName,
        shopPhone,
        currency,
        allowNegativeStock,
        lowStockThreshold,
        taxEnabled,
      ];
}
