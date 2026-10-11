import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

// جداول قاعدة البيانات
part 'app_database.g.dart';

// ─────────────────────────────────────────────
// جدول المستخدمين
// ─────────────────────────────────────────────
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().withLength(min: 2, max: 50)();
  TextColumn get passwordHash => text()();
  TextColumn get fullName => text().withLength(min: 2, max: 100)();
  TextColumn get role => text()(); // admin, finance, cashier
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastLoginAt => dateTime().nullable()();
}

// ─────────────────────────────────────────────
// جدول إعدادات التطبيق
// ─────────────────────────────────────────────
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

// ─────────────────────────────────────────────
// جدول التصنيفات
// ─────────────────────────────────────────────
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────
// جدول الأنواع (تحت التصنيفات)
// ─────────────────────────────────────────────
class ProductTypes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.restrict)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────
// جدول المنتجات
// ─────────────────────────────────────────────
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get barcode => text().nullable()();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id, onDelete: KeyAction.setNull)();
  IntColumn get productTypeId =>
      integer().nullable().references(ProductTypes, #id, onDelete: KeyAction.setNull)();
  TextColumn get description => text().nullable()();
  TextColumn get unit => text().withDefault(const Constant('قطعة'))();
  RealColumn get currentQuantity => real().withDefault(const Constant(0))();
  RealColumn get minQuantity => real().withDefault(const Constant(0))();
  RealColumn get costPrice => real().withDefault(const Constant(0))();
  RealColumn get sellPrice => real().withDefault(const Constant(0))();
  RealColumn get groupPrice => real().withDefault(const Constant(0))();
  RealColumn get groupQuantity => real().withDefault(const Constant(1))();
  RealColumn get weightedAvgCost => real().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────
// جدول حركات المخزون
// ─────────────────────────────────────────────
class InventoryMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.restrict)();
  TextColumn get movementType =>
      text()(); // purchase, sale, customer_return, supplier_return, manual_add, manual_remove, damage, inventory_adj
  RealColumn get quantity => real()(); // موجب أو سالب
  RealColumn get costPrice => real().withDefault(const Constant(0))();
  RealColumn get quantityBefore => real().withDefault(const Constant(0))();
  RealColumn get quantityAfter => real().withDefault(const Constant(0))();
  IntColumn get referenceId => integer().nullable()(); // فاتورة أو مرجع
  TextColumn get referenceType => text().nullable()(); // sale, purchase, etc.
  TextColumn get reason => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get userId =>
      integer().nullable().references(Users, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────
// جدول العملاء
// ─────────────────────────────────────────────
class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get phone => text().nullable()();
  TextColumn get whatsapp => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get notes => text().nullable()();
  RealColumn get totalBalance =>
      real().withDefault(const Constant(0))(); // مديونية (موجب = عليه)
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastTransactionAt => dateTime().nullable()();
}

// ─────────────────────────────────────────────
// جدول معاملات العملاء
// ─────────────────────────────────────────────
class CustomerTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId =>
      integer().references(Customers, #id, onDelete: KeyAction.restrict)();
  TextColumn get transactionType =>
      text()(); // sale, payment, return, adjustment
  RealColumn get amount => real()(); // موجب = على العميل، سالب = للعميل
  RealColumn get balanceBefore => real().withDefault(const Constant(0))();
  RealColumn get balanceAfter => real().withDefault(const Constant(0))();
  IntColumn get referenceId => integer().nullable()();
  TextColumn get referenceType => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get userId =>
      integer().nullable().references(Users, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────
// جدول الموردين
// ─────────────────────────────────────────────
class Suppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get company => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get whatsapp => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get notes => text().nullable()();
  RealColumn get totalBalance =>
      real().withDefault(const Constant(0))(); // مديونية (موجب = لهم)
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastTransactionAt => dateTime().nullable()();
}

// ─────────────────────────────────────────────
// جدول معاملات الموردين
// ─────────────────────────────────────────────
class SupplierTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get supplierId =>
      integer().references(Suppliers, #id, onDelete: KeyAction.restrict)();
  TextColumn get transactionType =>
      text()(); // purchase, payment, return, adjustment
  RealColumn get amount => real()();
  RealColumn get balanceBefore => real().withDefault(const Constant(0))();
  RealColumn get balanceAfter => real().withDefault(const Constant(0))();
  IntColumn get referenceId => integer().nullable()();
  TextColumn get referenceType => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get userId =>
      integer().nullable().references(Users, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────
// جدول المبيعات (الفواتير)
// ─────────────────────────────────────────────
class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNumber => text()();
  IntColumn get customerId =>
      integer().nullable().references(Customers, #id, onDelete: KeyAction.setNull)();
  RealColumn get subtotal => real().withDefault(const Constant(0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  RealColumn get discountPercent => real().withDefault(const Constant(0))();
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  RealColumn get remainingAmount => real().withDefault(const Constant(0))();
  RealColumn get costAmount => real().withDefault(const Constant(0))();
  RealColumn get profitAmount => real().withDefault(const Constant(0))();
  TextColumn get paymentType =>
      text().withDefault(const Constant('cash'))(); // cash, credit
  TextColumn get status =>
      text().withDefault(const Constant('completed'))(); // completed, cancelled, voided
  TextColumn get notes => text().nullable()();
  TextColumn get cancelReason => text().nullable()();
  IntColumn get userId =>
      integer().nullable().references(Users, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────
// جدول تفاصيل المبيعات
// ─────────────────────────────────────────────
class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId =>
      integer().references(Sales, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.restrict)();
  TextColumn get productName => text()(); // نسخة من الاسم وقت البيع
  TextColumn get productBarcode => text().nullable()();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()();
  RealColumn get costPrice => real()();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  RealColumn get totalPrice => real()();
  RealColumn get totalCost => real()();
  RealColumn get profitAmount => real()();
  TextColumn get priceType =>
      text().withDefault(const Constant('unit'))(); // unit, group
}

// ─────────────────────────────────────────────
// جدول المشتريات
// ─────────────────────────────────────────────
class Purchases extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNumber => text()();
  IntColumn get supplierId =>
      integer().nullable().references(Suppliers, #id, onDelete: KeyAction.setNull)();
  RealColumn get subtotal => real().withDefault(const Constant(0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  RealColumn get remainingAmount => real().withDefault(const Constant(0))();
  TextColumn get paymentType =>
      text().withDefault(const Constant('cash'))(); // cash, credit
  TextColumn get status =>
      text().withDefault(const Constant('completed'))(); // completed, cancelled
  TextColumn get notes => text().nullable()();
  TextColumn get cancelReason => text().nullable()();
  IntColumn get userId =>
      integer().nullable().references(Users, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────
// جدول تفاصيل المشتريات
// ─────────────────────────────────────────────
class PurchaseItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get purchaseId =>
      integer().references(Purchases, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.restrict)();
  TextColumn get productName => text()();
  RealColumn get quantity => real()();
  RealColumn get unitCost => real()();
  RealColumn get totalCost => real()();
}

// ─────────────────────────────────────────────
// جدول المرتجعات
// ─────────────────────────────────────────────
class Returns extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get returnNumber => text()();
  TextColumn get returnType => text()(); // customer, supplier
  IntColumn get originalSaleId =>
      integer().nullable().references(Sales, #id, onDelete: KeyAction.setNull)();
  IntColumn get originalPurchaseId =>
      integer().nullable().references(Purchases, #id, onDelete: KeyAction.setNull)();
  IntColumn get customerId =>
      integer().nullable().references(Customers, #id, onDelete: KeyAction.setNull)();
  IntColumn get supplierId =>
      integer().nullable().references(Suppliers, #id, onDelete: KeyAction.setNull)();
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  RealColumn get refundAmount => real().withDefault(const Constant(0))();
  TextColumn get refundType => text().withDefault(const Constant('cash'))(); // cash, balance
  TextColumn get reason => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get userId =>
      integer().nullable().references(Users, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────
// جدول تفاصيل المرتجعات
// ─────────────────────────────────────────────
class ReturnItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get returnId =>
      integer().references(Returns, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.restrict)();
  TextColumn get productName => text()();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()();
  RealColumn get totalPrice => real()();
}

// ─────────────────────────────────────────────
// جدول المصروفات
// ─────────────────────────────────────────────
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text()(); // كهرباء، إيجار، مياه، مرتبات، أخرى
  TextColumn get description => text()();
  RealColumn get amount => real()();
  TextColumn get paymentMethod =>
      text().withDefault(const Constant('cash'))();
  TextColumn get notes => text().nullable()();
  IntColumn get userId =>
      integer().nullable().references(Users, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get expenseDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────
// جدول حركات الخزينة
// ─────────────────────────────────────────────
class CashTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get transactionType =>
      text()(); // sale_income, purchase_payment, expense, customer_payment, supplier_payment, cash_in, cash_out
  RealColumn get amount => real()(); // موجب = دخل، سالب = خرج
  RealColumn get balanceBefore => real().withDefault(const Constant(0))();
  RealColumn get balanceAfter => real().withDefault(const Constant(0))();
  TextColumn get description => text()();
  IntColumn get referenceId => integer().nullable()();
  TextColumn get referenceType => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get sessionId => integer().nullable()();
  IntColumn get userId =>
      integer().nullable().references(Users, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────
// جدول جلسات الصندوق اليومية
// ─────────────────────────────────────────────
class CashSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get openedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get closedAt => dateTime().nullable()();
  RealColumn get openingBalance => real().withDefault(const Constant(0))();
  RealColumn get expectedBalance => real().withDefault(const Constant(0))();
  RealColumn get actualBalance => real().nullable()();
  RealColumn get difference => real().nullable()();
  TextColumn get status => text().withDefault(const Constant('open'))(); // open, closed
  TextColumn get notes => text().nullable()();
  IntColumn get userId =>
      integer().nullable().references(Users, #id, onDelete: KeyAction.setNull)();
}

// ─────────────────────────────────────────────
// جدول التوالف
// ─────────────────────────────────────────────
class StockDamages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.restrict)();
  TextColumn get productName => text()();
  RealColumn get quantity => real()();
  RealColumn get costPrice => real()();
  RealColumn get totalCost => real()();
  TextColumn get reason => text()();
  TextColumn get notes => text().nullable()();
  IntColumn get userId =>
      integer().nullable().references(Users, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────
// جدول تسويات المخزون (الجرد)
// ─────────────────────────────────────────────
class StockAdjustments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get adjustmentNumber => text()();
  TextColumn get status =>
      text().withDefault(const Constant('draft'))(); // draft, approved
  TextColumn get notes => text().nullable()();
  IntColumn get approvedBy =>
      integer().nullable().references(Users, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get approvedAt => dateTime().nullable()();
  IntColumn get userId =>
      integer().nullable().references(Users, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────
// جدول تفاصيل تسويات المخزون
// ─────────────────────────────────────────────
class StockAdjustmentItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get adjustmentId =>
      integer().references(StockAdjustments, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.restrict)();
  TextColumn get productName => text()();
  RealColumn get systemQuantity => real()();
  RealColumn get actualQuantity => real()();
  RealColumn get difference => real()();
}

// ─────────────────────────────────────────────
// جدول سجل العمليات (Audit Log)
// ─────────────────────────────────────────────
class AuditLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().nullable()();
  TextColumn get username => text().nullable()();
  TextColumn get action => text()(); // create, update, delete, login, etc.
  TextColumn get entityType => text()(); // product, sale, purchase, etc.
  IntColumn get entityId => integer().nullable()();
  TextColumn get oldValues => text().nullable()(); // JSON
  TextColumn get newValues => text().nullable()(); // JSON
  TextColumn get description => text()();
  TextColumn get ipAddress => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────
// قاعدة البيانات الرئيسية
// ─────────────────────────────────────────────
@DriftDatabase(tables: [
  Users,
  AppSettings,
  Categories,
  ProductTypes,
  Products,
  InventoryMovements,
  Customers,
  CustomerTransactions,
  Suppliers,
  SupplierTransactions,
  Sales,
  SaleItems,
  Purchases,
  PurchaseItems,
  Returns,
  ReturnItems,
  Expenses,
  CashTransactions,
  CashSessions,
  StockDamages,
  StockAdjustments,
  StockAdjustmentItems,
  AuditLogs,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openDatabase());
  AppDatabase.forTesting(super.e);

  static QueryExecutor _openDatabase() {
    return driftDatabase(name: 'screena_shop.db');
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedInitialData();
        },
        onUpgrade: (m, from, to) async {
          // ترقيات مستقبلية
        },
      );

  Future<void> _seedInitialData() async {
    // إنشاء مستخدم المدير الافتراضي
    // كلمة المرور: admin123
    await into(users).insert(UsersCompanion.insert(
      username: 'admin',
      passwordHash:
          '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', // SHA-256 of "admin123"
      fullName: 'المدير',
      role: 'admin',
    ));

    // إعدادات افتراضية
    final defaultSettings = {
      'shop_name': 'Screena Shop',
      'shop_address': '',
      'shop_phone': '',
      'currency': 'ج',
      'currency_decimals': '2',
      'allow_negative_stock': 'false',
      'low_stock_threshold': '10',
      'invoice_footer': 'شكراً لتعاملكم معنا',
      'tax_rate': '0',
      'tax_enabled': 'false',
      'whatsapp_enabled': 'false',
      'backup_path': '',
    };

    for (final entry in defaultSettings.entries) {
      await into(appSettings).insert(
        AppSettingsCompanion.insert(key: entry.key, value: entry.value),
      );
    }

    // فئات افتراضية
    final defaultCategories = [
      'مشروبات',
      'مواد غذائية',
      'منظفات',
      'إلكترونيات',
      'أخرى',
    ];

    for (final cat in defaultCategories) {
      await into(categories).insert(
        CategoriesCompanion.insert(name: cat),
      );
    }
  }

  // ─────────────────────────────────────────────
  // رصيد الخزينة الحالي
  // ─────────────────────────────────────────────
  Future<double> getCurrentCashBalance() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(amount), 0) as balance FROM cash_transactions',
      readsFrom: {cashTransactions},
    ).getSingle();
    return result.read<double>('balance');
  }

  // ─────────────────────────────────────────────
  // إحصائيات اليوم للـ Dashboard
  // ─────────────────────────────────────────────
  Future<Map<String, double>> getTodayStats() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final todaySales = await (select(sales)
          ..where((s) =>
              s.createdAt.isBiggerOrEqualValue(startOfDay) &
              s.createdAt.isSmallerThanValue(endOfDay) &
              s.status.equals('completed')))
        .get();

    final todayPurchases = await (select(purchases)
          ..where((p) =>
              p.createdAt.isBiggerOrEqualValue(startOfDay) &
              p.createdAt.isSmallerThanValue(endOfDay) &
              p.status.equals('completed')))
        .get();

    final todayExpenses = await (select(expenses)
          ..where((e) =>
              e.expenseDate.isBiggerOrEqualValue(startOfDay) &
              e.expenseDate.isSmallerThanValue(endOfDay)))
        .get();

    final totalSales =
        todaySales.fold(0.0, (sum, s) => sum + s.totalAmount);
    final totalPurchases =
        todayPurchases.fold(0.0, (sum, p) => sum + p.paidAmount);
    final totalExpenses =
        todayExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalProfit =
        todaySales.fold(0.0, (sum, s) => sum + s.profitAmount);
    final cashBalance = await getCurrentCashBalance();

    final invoiceCount = todaySales.length.toDouble();

    return {
      'today_sales': totalSales,
      'today_purchases': totalPurchases,
      'today_expenses': totalExpenses,
      'today_profit': totalProfit,
      'cash_balance': cashBalance,
      'invoice_count': invoiceCount,
    };
  }

  // ─────────────────────────────────────────────
  // منتجات منخفضة المخزون
  // ─────────────────────────────────────────────
  Future<List<Product>> getLowStockProducts() async {
    return (select(products)
          ..where(
            (p) =>
                p.currentQuantity.isSmallerOrEqual(p.minQuantity) &
                p.status.equals('active'),
          )
          ..orderBy([(p) => OrderingTerm.asc(p.currentQuantity)]))
        .get();
  }

  // رصيد العملاء المستحق
  Future<double> getTotalCustomersBalance() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(total_balance), 0) as balance FROM customers WHERE total_balance > 0',
      readsFrom: {customers},
    ).getSingle();
    return result.read<double>('balance');
  }

  // رصيد الموردين المستحق
  Future<double> getTotalSuppliersBalance() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(total_balance), 0) as balance FROM suppliers WHERE total_balance > 0',
      readsFrom: {suppliers},
    ).getSingle();
    return result.read<double>('balance');
  }

  // قيمة المخزون الإجمالية
  Future<double> getTotalInventoryValue() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(current_quantity * weighted_avg_cost), 0) as value FROM products WHERE status = \'active\'',
      readsFrom: {products},
    ).getSingle();
    return result.read<double>('value');
  }

  // ─────────────────────────────────────────────
  // التحقق من كلمة مرور المدير
  // ─────────────────────────────────────────────
  Future<bool> verifyAdminPassword(String password) async {
    final hash = sha256.convert(utf8.encode(password)).toString();
    final admin = await (select(users)
          ..where((u) =>
              u.role.equals('admin') &
              u.passwordHash.equals(hash) &
              u.isActive.equals(true)))
        .getSingleOrNull();
    return admin != null;
  }

  // ─────────────────────────────────────────────
  // ترجيع الكل كما كان (إعادة ضبط المصنع بالكامل وتصفير النظام)
  // ─────────────────────────────────────────────
  Future<void> factoryReset() async {
    await transaction(() async {
      // 1. تفريغ المبيعات وتفاصيلها
      await delete(saleItems).go();
      await delete(sales).go();

      // 2. تفريغ المشتريات وتفاصيلها
      await delete(purchaseItems).go();
      await delete(purchases).go();

      // 3. تفريغ المرتجعات وتفاصيلها
      await delete(returnItems).go();
      await delete(returns).go();

      // 4. تفريغ الجرد والهالك وحركات المخزون
      await delete(stockAdjustmentItems).go();
      await delete(stockAdjustments).go();
      await delete(stockDamages).go();
      await delete(inventoryMovements).go();

      // 5. تصفير الخزينة وجلسات الصندوق
      await delete(cashTransactions).go();
      await delete(cashSessions).go();

      // 6. تفريغ المصروفات
      await delete(expenses).go();

      // 7. تفريغ العملاء ومعاملاتهم
      await delete(customerTransactions).go();
      await delete(customers).go();

      // 8. تفريغ الموردين ومعاملاتهم
      await delete(supplierTransactions).go();
      await delete(suppliers).go();

      // 9. تفريغ المنتجات والأنواع
      await delete(products).go();
      await delete(productTypes).go();

      // 10. تفريغ سجل العمليات
      await delete(auditLogs).go();

      // 11. إعادة التصنيفات الافتراضية
      await delete(categories).go();
      final defaultCategories = [
        'مشروبات',
        'مواد غذائية',
        'منظفات',
        'إلكترونيات',
        'أخرى',
      ];
      for (final cat in defaultCategories) {
        await into(categories).insert(
          CategoriesCompanion.insert(name: cat),
        );
      }

      // 12. حذف المستخدمين الإضافيين والإبقاء على المدير الافتراضي
      await (delete(users)..where((u) => u.username.isNotValue('admin'))).go();
      final adminUser = await (select(users)
            ..where((u) => u.username.equals('admin')))
          .getSingleOrNull();
      if (adminUser == null) {
        await into(users).insert(UsersCompanion.insert(
          username: 'admin',
          passwordHash:
              '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9',
          fullName: 'المدير',
          role: 'admin',
        ));
      }
    });
  }
}

