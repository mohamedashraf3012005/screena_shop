import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/supplier_entity.dart';

class SuppliersLocalDatasource {
  final AppDatabase _db;
  SuppliersLocalDatasource(this._db);

  Future<List<SupplierEntity>> getAll({String? search, int page = 1, int pageSize = 50}) async {
    final query = _db.select(_db.suppliers);
    if (search != null && search.trim().isNotEmpty) {
      final term = '%${search.trim()}%';
      query.where((s) => s.name.like(term) | s.phone.like(term) | s.company.like(term));
    }
    query.orderBy([(s) => OrderingTerm.asc(s.name)]);
    query.limit(pageSize, offset: (page - 1) * pageSize);

    final rows = await query.get();
    return rows
        .map((r) => SupplierEntity(
              id: r.id,
              name: r.name,
              company: r.company,
              phone: r.phone,
              whatsapp: r.whatsapp,
              address: r.address,
              notes: r.notes,
              totalBalance: r.totalBalance,
              isActive: r.isActive,
              createdAt: r.createdAt,
              lastTransactionAt: r.lastTransactionAt,
            ))
        .toList();
  }

  Future<SupplierEntity?> getById(int id) async {
    final row = await (_db.select(_db.suppliers)..where((s) => s.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return SupplierEntity(
      id: row.id,
      name: row.name,
      company: row.company,
      phone: row.phone,
      whatsapp: row.whatsapp,
      address: row.address,
      notes: row.notes,
      totalBalance: row.totalBalance,
      isActive: row.isActive,
      createdAt: row.createdAt,
      lastTransactionAt: row.lastTransactionAt,
    );
  }

  Future<int> create(SupplierEntity s) async {
    final id = await _db.into(_db.suppliers).insert(SuppliersCompanion.insert(
          name: s.name,
          company: Value(s.company),
          phone: Value(s.phone),
          whatsapp: Value(s.whatsapp),
          address: Value(s.address),
          notes: Value(s.notes),
          totalBalance: Value(s.totalBalance),
          isActive: Value(s.isActive),
        ));

    if (s.totalBalance > 0) {
      await _db.into(_db.supplierTransactions).insert(SupplierTransactionsCompanion.insert(
            supplierId: id,
            transactionType: 'adjustment',
            amount: s.totalBalance,
            balanceBefore: const Value(0),
            balanceAfter: Value(s.totalBalance),
            notes: const Value('رصيد افتتاحي سابق'),
          ));
    }
    return id;
  }

  Future<bool> update(SupplierEntity s) async {
    final count = await (_db.update(_db.suppliers)..where((tbl) => tbl.id.equals(s.id))).write(
      SuppliersCompanion(
        name: Value(s.name),
        company: Value(s.company),
        phone: Value(s.phone),
        whatsapp: Value(s.whatsapp),
        address: Value(s.address),
        notes: Value(s.notes),
        isActive: Value(s.isActive),
      ),
    );
    return count > 0;
  }

  Future<bool> delete(int id) async {
    final count = await (_db.delete(_db.suppliers)..where((tbl) => tbl.id.equals(id))).go();
    return count > 0;
  }

  Future<List<SupplierTransactionEntity>> getTransactions(int supplierId) async {
    final rows = await (_db.select(_db.supplierTransactions)
          ..where((t) => t.supplierId.equals(supplierId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();

    return rows
        .map((r) => SupplierTransactionEntity(
              id: r.id,
              supplierId: r.supplierId,
              transactionType: r.transactionType,
              amount: r.amount,
              balanceBefore: r.balanceBefore,
              balanceAfter: r.balanceAfter,
              referenceId: r.referenceId,
              referenceType: r.referenceType,
              notes: r.notes,
              createdAt: r.createdAt,
            ))
        .toList();
  }

  Future<void> addPayment({
    required int supplierId,
    required double amount,
    required String notes,
    int? userId,
  }) async {
    await _db.transaction(() async {
      final supplier = await (_db.select(_db.suppliers)..where((s) => s.id.equals(supplierId))).getSingle();
      final currentBal = supplier.totalBalance;
      final newBal = currentBal - amount;

      // Update supplier balance
      await (_db.update(_db.suppliers)..where((s) => s.id.equals(supplierId))).write(
        SuppliersCompanion(
          totalBalance: Value(newBal),
          lastTransactionAt: Value(DateTime.now()),
        ),
      );

      // Log supplier transaction
      await _db.into(_db.supplierTransactions).insert(SupplierTransactionsCompanion.insert(
            supplierId: supplierId,
            transactionType: 'payment',
            amount: -amount,
            balanceBefore: Value(currentBal),
            balanceAfter: Value(newBal),
            notes: Value(notes),
            userId: Value(userId),
          ));

      // Log cash transaction (money out from treasury)
      final cashBefore = await _db.getCurrentCashBalance();
      await _db.into(_db.cashTransactions).insert(CashTransactionsCompanion.insert(
            transactionType: 'supplier_payment',
            amount: -amount,
            balanceBefore: Value(cashBefore),
            balanceAfter: Value(cashBefore - amount),
            description: 'سداد للمورد: ${supplier.name} - $notes',
            referenceId: Value(supplierId),
            referenceType: const Value('supplier'),
            notes: Value(notes),
            userId: Value(userId),
          ));
    });
  }
}
