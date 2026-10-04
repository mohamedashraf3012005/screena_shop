import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/customer_entity.dart';

class CustomersLocalDatasource {
  final AppDatabase _db;
  CustomersLocalDatasource(this._db);

  Future<List<CustomerEntity>> getAll({
    String? search,
    int page = 1,
    int pageSize = 50,
  }) async {
    final query = _db.select(_db.customers);
    query.where((c) => c.isActive.equals(true));
    if (search != null && search.isNotEmpty) {
      query.where((c) =>
          c.name.contains(search) | c.phone.contains(search));
    }
    query.orderBy([(c) => OrderingTerm.asc(c.name)]);
    query.limit(pageSize, offset: (page - 1) * pageSize);

    final rows = await query.get();
    return rows.map(_toEntity).toList();
  }

  Future<CustomerEntity?> getById(int id) async {
    final row = await (_db.select(_db.customers)
          ..where((c) => c.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _toEntity(row) : null;
  }

  Future<int> create(CustomerEntity entity) async {
    return await _db.into(_db.customers).insert(CustomersCompanion.insert(
          name: entity.name,
          phone: Value(entity.phone),
          whatsapp: Value(entity.whatsapp),
          address: Value(entity.address),
          notes: Value(entity.notes),
        ));
  }

  Future<void> update(CustomerEntity entity) async {
    await (_db.update(_db.customers)
          ..where((c) => c.id.equals(entity.id)))
        .write(CustomersCompanion(
      name: Value(entity.name),
      phone: Value(entity.phone),
      whatsapp: Value(entity.whatsapp),
      address: Value(entity.address),
      notes: Value(entity.notes),
    ));
  }

  Future<void> delete(int id) async {
    await (_db.update(_db.customers)..where((c) => c.id.equals(id))).write(
      const CustomersCompanion(isActive: Value(false)),
    );
  }

  Future<List<CustomerTransactionEntity>> getTransactions(int customerId) async {
    final rows = await (_db.select(_db.customerTransactions)
          ..where((t) => t.customerId.equals(customerId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map((r) => CustomerTransactionEntity(
          id: r.id,
          customerId: r.customerId,
          transactionType: r.transactionType,
          amount: r.amount,
          balanceBefore: r.balanceBefore,
          balanceAfter: r.balanceAfter,
          referenceId: r.referenceId,
          referenceType: r.referenceType,
          notes: r.notes,
          createdAt: r.createdAt,
        )).toList();
  }

  Future<void> addPayment({
    required int customerId,
    required double amount,
    required String notes,
    required int? userId,
  }) async {
    await _db.transaction(() async {
      final customer = await (_db.select(_db.customers)
            ..where((c) => c.id.equals(customerId)))
          .getSingle();
      final balanceBefore = customer.totalBalance;
      final balanceAfter = balanceBefore - amount;

      // إضافة معاملة العميل
      await _db.into(_db.customerTransactions).insert(
            CustomerTransactionsCompanion.insert(
              customerId: customerId,
              transactionType: 'payment',
              amount: -amount,
              balanceBefore: Value(balanceBefore),
              balanceAfter: Value(balanceAfter),
              notes: Value(notes.isEmpty ? null : notes),
              userId: Value(userId),
            ),
          );

      // تحديث رصيد العميل
      await (_db.update(_db.customers)
            ..where((c) => c.id.equals(customerId)))
          .write(CustomersCompanion(
        totalBalance: Value(balanceAfter),
        lastTransactionAt: Value(DateTime.now()),
      ));

      // إضافة حركة خزينة
      final cashBalance = await _db.getCurrentCashBalance();
      await _db.into(_db.cashTransactions).insert(
            CashTransactionsCompanion.insert(
              transactionType: 'customer_payment',
              amount: amount,
              balanceBefore: Value(cashBalance),
              balanceAfter: Value(cashBalance + amount),
              description: 'تحصيل من عميل: ${customer.name}',
              userId: Value(userId),
              notes: Value(notes.isEmpty ? null : notes),
            ),
          );
    });
  }

  CustomerEntity _toEntity(Customer c) => CustomerEntity(
        id: c.id,
        name: c.name,
        phone: c.phone,
        whatsapp: c.whatsapp,
        address: c.address,
        notes: c.notes,
        totalBalance: c.totalBalance,
        isActive: c.isActive,
        createdAt: c.createdAt,
        lastTransactionAt: c.lastTransactionAt,
      );
}
