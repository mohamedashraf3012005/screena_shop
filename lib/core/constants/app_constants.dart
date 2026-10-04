class AppConstants {
  // أنواع الأدوار
  static const String roleAdmin = 'admin';
  static const String roleFinance = 'finance';
  static const String roleCashier = 'cashier';

  // أنواع حركات المخزون
  static const String movePurchase = 'purchase';
  static const String moveSale = 'sale';
  static const String moveCustomerReturn = 'customer_return';
  static const String moveSupplierReturn = 'supplier_return';
  static const String moveManualAdd = 'manual_add';
  static const String moveManualRemove = 'manual_remove';
  static const String moveDamage = 'damage';
  static const String moveInventoryAdj = 'inventory_adj';

  // أنواع معاملات الخزينة
  static const String cashSaleIncome = 'sale_income';
  static const String cashPurchasePayment = 'purchase_payment';
  static const String cashExpense = 'expense';
  static const String cashCustomerPayment = 'customer_payment';
  static const String cashSupplierPayment = 'supplier_payment';
  static const String cashIn = 'cash_in';
  static const String cashOut = 'cash_out';
  static const String cashReturn = 'customer_return';

  // حالات الفاتورة
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  static const String statusVoided = 'voided';

  // أنواع الدفع
  static const String paymentCash = 'cash';
  static const String paymentCredit = 'credit';

  // أنواع المرتجع
  static const String returnCustomer = 'customer';
  static const String returnSupplier = 'supplier';

  // فئات المصروفات
  static const List<String> expenseCategories = [
    'كهرباء',
    'إيجار',
    'مياه',
    'نقل',
    'مرتبات',
    'صيانة',
    'تسويق',
    'مصروفات أخرى',
  ];

  // أنواع حركات العملاء/الموردين
  static const String transSale = 'sale';
  static const String transPayment = 'payment';
  static const String transReturn = 'return';
  static const String transAdjustment = 'adjustment';
}
