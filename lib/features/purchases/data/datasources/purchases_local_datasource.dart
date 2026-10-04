import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/purchase_entity.dart';

class PurchasesLocalDatasource {
  final AppDatabase _db;
  PurchasesLocalDatasource(this._db);

  Future<List<PurchaseEntity>> getAllPurchases({
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
    int? supplierId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final query = _db.select(_db.purchases).join([
      leftOuterJoin(_db.suppliers, _db.suppliers.id.equalsExp(_db.purchases.supplierId)),
    ]);

    if (search != null && search.trim().isNotEmpty) {
      final term = '%${search.trim()}%';
      query.where(_db.purchases.invoiceNumber.like(term) | _db.suppliers.name.like(term));
    }

    if (fromDate != null) {
      query.where(_db.purchases.createdAt.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where(_db.purchases.createdAt.isSmallerOrEqualValue(toDate));
    }
    if (supplierId != null) {
      query.where(_db.purchases.supplierId.equals(supplierId));
    }

    query.orderBy([OrderingTerm.desc(_db.purchases.createdAt)]);
    query.limit(pageSize, offset: (page - 1) * pageSize);

    final rows = await query.get();

    final List<PurchaseEntity> list = [];
    for (final row in rows) {
      final p = row.readTable(_db.purchases);
      final s = row.readTableOrNull(_db.suppliers);

      final items = await (_db.select(_db.purchaseItems)..where((i) => i.purchaseId.equals(p.id))).get();

      list.add(PurchaseEntity(
        id: p.id,
        invoiceNumber: p.invoiceNumber,
        supplierId: p.supplierId,
        supplierName: s?.name,
        subtotal: p.subtotal,
        discountAmount: p.discountAmount,
        totalAmount: p.totalAmount,
        paidAmount: p.paidAmount,
        remainingAmount: p.remainingAmount,
        paymentType: p.paymentType,
        status: p.status,
        notes: p.notes,
        cancelReason: p.cancelReason,
        userId: p.userId,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
        items: items
            .map((i) => PurchaseItemEntity(
                  id: i.id,
                  purchaseId: i.purchaseId,
                  productId: i.productId,
                  productName: i.productName,
                  quantity: i.quantity,
                  unitCost: i.unitCost,
                  totalCost: i.totalCost,
                ))
            .toList(),
      ));
    }

    return list;
  }

  Future<PurchaseEntity?> getPurchaseById(int id) async {
    final p = await (_db.select(_db.purchases)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (p == null) return null;

    String? supplierName;
    if (p.supplierId != null) {
      final s = await (_db.select(_db.suppliers)..where((tbl) => tbl.id.equals(p.supplierId!))).getSingleOrNull();
      supplierName = s?.name;
    }

    final items = await (_db.select(_db.purchaseItems)..where((i) => i.purchaseId.equals(p.id))).get();

    return PurchaseEntity(
      id: p.id,
      invoiceNumber: p.invoiceNumber,
      supplierId: p.supplierId,
      supplierName: supplierName,
      subtotal: p.subtotal,
      discountAmount: p.discountAmount,
      totalAmount: p.totalAmount,
      paidAmount: p.paidAmount,
      remainingAmount: p.remainingAmount,
      paymentType: p.paymentType,
      status: p.status,
      notes: p.notes,
      cancelReason: p.cancelReason,
      userId: p.userId,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
      items: items
          .map((i) => PurchaseItemEntity(
                id: i.id,
                purchaseId: i.purchaseId,
                productId: i.productId,
                productName: i.productName,
                quantity: i.quantity,
                unitCost: i.unitCost,
                totalCost: i.totalCost,
              ))
          .toList(),
    );
  }

  Future<int> createPurchase({
    required PurchaseEntity purchase,
    required List<PurchaseItemEntity> items,
  }) async {
    return await _db.transaction(() async {
      final invNumber = purchase.invoiceNumber.isNotEmpty
          ? purchase.invoiceNumber
          : 'PUR-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

      // 1. Insert into Purchases
      final purchaseId = await _db.into(_db.purchases).insert(
            PurchasesCompanion.insert(
              invoiceNumber: invNumber,
              supplierId: Value(purchase.supplierId),
              subtotal: Value(purchase.subtotal),
              discountAmount: Value(purchase.discountAmount),
              totalAmount: Value(purchase.totalAmount),
              paidAmount: Value(purchase.paidAmount),
              remainingAmount: Value(purchase.remainingAmount),
              paymentType: Value(purchase.paymentType),
              status: const Value('completed'),
              notes: Value(purchase.notes),
              userId: Value(purchase.userId),
            ),
          );

      // 2. Insert items and update stock & weighted average cost
      for (final item in items) {
        await _db.into(_db.purchaseItems).insert(
              PurchaseItemsCompanion.insert(
                purchaseId: purchaseId,
                productId: item.productId,
                productName: item.productName,
                quantity: item.quantity,
                unitCost: item.unitCost,
                totalCost: item.totalCost,
              ),
            );

        final product = await (_db.select(_db.products)..where((p) => p.id.equals(item.productId))).getSingle();
        final qtyBefore = product.currentQuantity;
        final qtyAfter = qtyBefore + item.quantity;

        // Weighted Average Cost calculation
        double newAvgCost = item.unitCost;
        if (qtyAfter > 0) {
          final oldTotalCost = (qtyBefore > 0 ? qtyBefore : 0) * product.weightedAvgCost;
          final newBatchCost = item.quantity * item.unitCost;
          newAvgCost = (oldTotalCost + newBatchCost) / (qtyAfter > 0 ? qtyAfter : 1);
        }

        await (_db.update(_db.products)..where((p) => p.id.equals(item.productId))).write(
          ProductsCompanion(
            currentQuantity: Value(qtyAfter),
            costPrice: Value(item.unitCost), // Latest cost
            weightedAvgCost: Value(newAvgCost),
            updatedAt: Value(DateTime.now()),
          ),
        );

        // Movement
        await _db.into(_db.inventoryMovements).insert(
              InventoryMovementsCompanion.insert(
                productId: item.productId,
                movementType: 'purchase',
                quantity: item.quantity,
                costPrice: Value(item.unitCost),
                quantityBefore: Value(qtyBefore),
                quantityAfter: Value(qtyAfter),
                referenceId: Value(purchaseId),
                referenceType: const Value('purchase'),
                reason: Value('فاتورة مشتريات #$invNumber'),
                userId: Value(purchase.userId),
              ),
            );
      }

      // 3. Cash movement if paidAmount > 0
      if (purchase.paidAmount > 0) {
        final cashBefore = await _db.getCurrentCashBalance();
        await _db.into(_db.cashTransactions).insert(
              CashTransactionsCompanion.insert(
                transactionType: 'purchase_payment',
                amount: -purchase.paidAmount,
                balanceBefore: Value(cashBefore),
                balanceAfter: Value(cashBefore - purchase.paidAmount),
                description: 'سداد فاتورة مشتريات #$invNumber',
                referenceId: Value(purchaseId),
                referenceType: const Value('purchase'),
                notes: Value(purchase.notes),
                userId: Value(purchase.userId),
              ),
            );
      }

      // 4. Supplier balance if remainingAmount > 0
      if (purchase.remainingAmount > 0 && purchase.supplierId != null) {
        final supplier = await (_db.select(_db.suppliers)..where((s) => s.id.equals(purchase.supplierId!))).getSingle();
        final balBefore = supplier.totalBalance;
        final balAfter = balBefore + purchase.remainingAmount;

        await (_db.update(_db.suppliers)..where((s) => s.id.equals(purchase.supplierId!))).write(
          SuppliersCompanion(
            totalBalance: Value(balAfter),
            lastTransactionAt: Value(DateTime.now()),
          ),
        );

        await _db.into(_db.supplierTransactions).insert(
              SupplierTransactionsCompanion.insert(
                supplierId: purchase.supplierId!,
                transactionType: 'purchase',
                amount: purchase.remainingAmount,
                balanceBefore: Value(balBefore),
                balanceAfter: Value(balAfter),
                referenceId: Value(purchaseId),
                referenceType: const Value('purchase'),
                notes: Value('متبقي فاتورة مشتريات #$invNumber'),
                userId: Value(purchase.userId),
              ),
            );
      }

      return purchaseId;
    });
  }

  Future<bool> cancelPurchase({
    required int id,
    required String reason,
    int? userId,
  }) async {
    return await _db.transaction(() async {
      final purchase = await (_db.select(_db.purchases)..where((p) => p.id.equals(id))).getSingle();
      if (purchase.status == 'cancelled') return false;

      // 1. Mark cancelled
      await (_db.update(_db.purchases)..where((p) => p.id.equals(id))).write(
        PurchasesCompanion(
          status: const Value('cancelled'),
          cancelReason: Value(reason),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // 2. Deduct product quantities
      final items = await (_db.select(_db.purchaseItems)..where((i) => i.purchaseId.equals(id))).get();
      for (final item in items) {
        final product = await (_db.select(_db.products)..where((p) => p.id.equals(item.productId))).getSingle();
        final qtyBefore = product.currentQuantity;
        final qtyAfter = qtyBefore - item.quantity;

        await (_db.update(_db.products)..where((p) => p.id.equals(item.productId))).write(
          ProductsCompanion(
            currentQuantity: Value(qtyAfter),
            updatedAt: Value(DateTime.now()),
          ),
        );

        await _db.into(_db.inventoryMovements).insert(
              InventoryMovementsCompanion.insert(
                productId: item.productId,
                movementType: 'supplier_return',
                quantity: -item.quantity,
                costPrice: Value(item.unitCost),
                quantityBefore: Value(qtyBefore),
                quantityAfter: Value(qtyAfter),
                referenceId: Value(id),
                referenceType: const Value('purchase_cancel'),
                reason: Value('إلغاء فاتورة مشتريات #${purchase.invoiceNumber}: $reason'),
                userId: Value(userId),
              ),
            );
      }

      // 3. Return cash if paid
      if (purchase.paidAmount > 0) {
        final cashBefore = await _db.getCurrentCashBalance();
        await _db.into(_db.cashTransactions).insert(
              CashTransactionsCompanion.insert(
                transactionType: 'cash_in',
                amount: purchase.paidAmount,
                balanceBefore: Value(cashBefore),
                balanceAfter: Value(cashBefore + purchase.paidAmount),
                description: 'استرداد نقدي لإلغاء فاتورة مشتريات #${purchase.invoiceNumber}',
                referenceId: Value(id),
                referenceType: const Value('purchase_cancel'),
                notes: Value(reason),
                userId: Value(userId),
              ),
            );
      }

      // 4. Reduce supplier balance if had credit
      if (purchase.remainingAmount > 0 && purchase.supplierId != null) {
        final supplier = await (_db.select(_db.suppliers)..where((s) => s.id.equals(purchase.supplierId!))).getSingle();
        final balBefore = supplier.totalBalance;
        final balAfter = balBefore - purchase.remainingAmount;

        await (_db.update(_db.suppliers)..where((s) => s.id.equals(purchase.supplierId!))).write(
          SuppliersCompanion(
            totalBalance: Value(balAfter),
            lastTransactionAt: Value(DateTime.now()),
          ),
        );

        await _db.into(_db.supplierTransactions).insert(
              SupplierTransactionsCompanion.insert(
                supplierId: purchase.supplierId!,
                transactionType: 'return',
                amount: -purchase.remainingAmount,
                balanceBefore: Value(balBefore),
                balanceAfter: Value(balAfter),
                referenceId: Value(id),
                referenceType: const Value('purchase_cancel'),
                notes: Value('إلغاء متبقي فاتورة مشتريات #${purchase.invoiceNumber}'),
                userId: Value(userId),
              ),
            );
      }

      return true;
    });
  }
}
