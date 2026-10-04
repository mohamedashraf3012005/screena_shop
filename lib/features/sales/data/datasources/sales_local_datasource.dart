import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/sale_entity.dart';

class SalesLocalDatasource {
  final AppDatabase _db;
  SalesLocalDatasource(this._db);

  Future<List<SaleEntity>> getAllSales({
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
    int? customerId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final query = _db.select(_db.sales).join([
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.sales.customerId)),
    ]);

    if (search != null && search.trim().isNotEmpty) {
      final term = '%${search.trim()}%';
      query.where(_db.sales.invoiceNumber.like(term) | _db.customers.name.like(term));
    }

    if (fromDate != null) {
      query.where(_db.sales.createdAt.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where(_db.sales.createdAt.isSmallerOrEqualValue(toDate));
    }
    if (customerId != null) {
      query.where(_db.sales.customerId.equals(customerId));
    }

    query.orderBy([OrderingTerm.desc(_db.sales.createdAt)]);
    query.limit(pageSize, offset: (page - 1) * pageSize);

    final rows = await query.get();

    final List<SaleEntity> salesList = [];
    for (final row in rows) {
      final s = row.readTable(_db.sales);
      final c = row.readTableOrNull(_db.customers);

      final items = await (_db.select(_db.saleItems)..where((i) => i.saleId.equals(s.id))).get();

      salesList.add(SaleEntity(
        id: s.id,
        invoiceNumber: s.invoiceNumber,
        customerId: s.customerId,
        customerName: c?.name,
        subtotal: s.subtotal,
        discountAmount: s.discountAmount,
        discountPercent: s.discountPercent,
        totalAmount: s.totalAmount,
        paidAmount: s.paidAmount,
        remainingAmount: s.remainingAmount,
        costAmount: s.costAmount,
        profitAmount: s.profitAmount,
        paymentType: s.paymentType,
        status: s.status,
        notes: s.notes,
        cancelReason: s.cancelReason,
        userId: s.userId,
        createdAt: s.createdAt,
        updatedAt: s.updatedAt,
        items: items
            .map((i) => SaleItemEntity(
                  id: i.id,
                  saleId: i.saleId,
                  productId: i.productId,
                  productName: i.productName,
                  productBarcode: i.productBarcode,
                  quantity: i.quantity,
                  unitPrice: i.unitPrice,
                  costPrice: i.costPrice,
                  discountAmount: i.discountAmount,
                  totalPrice: i.totalPrice,
                  totalCost: i.totalCost,
                  profitAmount: i.profitAmount,
                  priceType: i.priceType,
                ))
            .toList(),
      ));
    }

    return salesList;
  }

  Future<SaleEntity?> getSaleById(int id) async {
    final s = await (_db.select(_db.sales)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (s == null) return null;

    String? customerName;
    if (s.customerId != null) {
      final c = await (_db.select(_db.customers)..where((tbl) => tbl.id.equals(s.customerId!))).getSingleOrNull();
      customerName = c?.name;
    }

    final items = await (_db.select(_db.saleItems)..where((i) => i.saleId.equals(s.id))).get();

    return SaleEntity(
      id: s.id,
      invoiceNumber: s.invoiceNumber,
      customerId: s.customerId,
      customerName: customerName,
      subtotal: s.subtotal,
      discountAmount: s.discountAmount,
      discountPercent: s.discountPercent,
      totalAmount: s.totalAmount,
      paidAmount: s.paidAmount,
      remainingAmount: s.remainingAmount,
      costAmount: s.costAmount,
      profitAmount: s.profitAmount,
      paymentType: s.paymentType,
      status: s.status,
      notes: s.notes,
      cancelReason: s.cancelReason,
      userId: s.userId,
      createdAt: s.createdAt,
      updatedAt: s.updatedAt,
      items: items
          .map((i) => SaleItemEntity(
                id: i.id,
                saleId: i.saleId,
                productId: i.productId,
                productName: i.productName,
                productBarcode: i.productBarcode,
                quantity: i.quantity,
                unitPrice: i.unitPrice,
                costPrice: i.costPrice,
                discountAmount: i.discountAmount,
                totalPrice: i.totalPrice,
                totalCost: i.totalCost,
                profitAmount: i.profitAmount,
                priceType: i.priceType,
              ))
          .toList(),
    );
  }

  Future<int> createSale({
    required SaleEntity sale,
    required List<SaleItemEntity> items,
  }) async {
    return await _db.transaction(() async {
      final invNumber = sale.invoiceNumber.isNotEmpty
          ? sale.invoiceNumber
          : 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

      // 1. Insert into Sales
      final saleId = await _db.into(_db.sales).insert(
            SalesCompanion.insert(
              invoiceNumber: invNumber,
              customerId: Value(sale.customerId),
              subtotal: Value(sale.subtotal),
              discountAmount: Value(sale.discountAmount),
              discountPercent: Value(sale.discountPercent),
              totalAmount: Value(sale.totalAmount),
              paidAmount: Value(sale.paidAmount),
              remainingAmount: Value(sale.remainingAmount),
              costAmount: Value(sale.costAmount),
              profitAmount: Value(sale.profitAmount),
              paymentType: Value(sale.paymentType),
              status: const Value('completed'),
              notes: Value(sale.notes),
              userId: Value(sale.userId),
            ),
          );

      // 2. Insert items and update inventory
      for (final item in items) {
        await _db.into(_db.saleItems).insert(
              SaleItemsCompanion.insert(
                saleId: saleId,
                productId: item.productId,
                productName: item.productName,
                productBarcode: Value(item.productBarcode),
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                costPrice: item.costPrice,
                discountAmount: Value(item.discountAmount),
                totalPrice: item.totalPrice,
                totalCost: item.totalCost,
                profitAmount: item.profitAmount,
                priceType: Value(item.priceType),
              ),
            );

        // Update product quantity
        final product = await (_db.select(_db.products)..where((p) => p.id.equals(item.productId))).getSingle();
        final qtyBefore = product.currentQuantity;
        final qtyAfter = qtyBefore - item.quantity;

        await (_db.update(_db.products)..where((p) => p.id.equals(item.productId))).write(
          ProductsCompanion(
            currentQuantity: Value(qtyAfter),
            updatedAt: Value(DateTime.now()),
          ),
        );

        // Record inventory movement
        await _db.into(_db.inventoryMovements).insert(
              InventoryMovementsCompanion.insert(
                productId: item.productId,
                movementType: 'sale',
                quantity: -item.quantity,
                costPrice: Value(item.costPrice),
                quantityBefore: Value(qtyBefore),
                quantityAfter: Value(qtyAfter),
                referenceId: Value(saleId),
                referenceType: const Value('sale'),
                reason: Value('فاتورة مبيعات #$invNumber'),
                userId: Value(sale.userId),
              ),
            );
      }

      // 3. Cash movement if paidAmount > 0
      if (sale.paidAmount > 0) {
        final cashBefore = await _db.getCurrentCashBalance();
        await _db.into(_db.cashTransactions).insert(
              CashTransactionsCompanion.insert(
                transactionType: 'sale_income',
                amount: sale.paidAmount,
                balanceBefore: Value(cashBefore),
                balanceAfter: Value(cashBefore + sale.paidAmount),
                description: 'تحصيل مبيعات فاتورة #$invNumber',
                referenceId: Value(saleId),
                referenceType: const Value('sale'),
                notes: Value(sale.notes),
                userId: Value(sale.userId),
              ),
            );
      }

      // 4. Customer balance update if credit / remainingAmount > 0
      if (sale.remainingAmount > 0 && sale.customerId != null) {
        final customer = await (_db.select(_db.customers)..where((c) => c.id.equals(sale.customerId!))).getSingle();
        final balBefore = customer.totalBalance;
        final balAfter = balBefore + sale.remainingAmount;

        await (_db.update(_db.customers)..where((c) => c.id.equals(sale.customerId!))).write(
          CustomersCompanion(
            totalBalance: Value(balAfter),
            lastTransactionAt: Value(DateTime.now()),
          ),
        );

        await _db.into(_db.customerTransactions).insert(
              CustomerTransactionsCompanion.insert(
                customerId: sale.customerId!,
                transactionType: 'sale',
                amount: sale.remainingAmount,
                balanceBefore: Value(balBefore),
                balanceAfter: Value(balAfter),
                referenceId: Value(saleId),
                referenceType: const Value('sale'),
                notes: Value('متبقي فاتورة #$invNumber'),
                userId: Value(sale.userId),
              ),
            );
      }

      return saleId;
    });
  }

  Future<bool> cancelSale({
    required int id,
    required String reason,
    int? userId,
  }) async {
    return await _db.transaction(() async {
      final sale = await (_db.select(_db.sales)..where((s) => s.id.equals(id))).getSingle();
      if (sale.status == 'cancelled') return false;

      // 1. Mark cancelled
      await (_db.update(_db.sales)..where((s) => s.id.equals(id))).write(
        SalesCompanion(
          status: const Value('cancelled'),
          cancelReason: Value(reason),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // 2. Restore products quantities
      final items = await (_db.select(_db.saleItems)..where((i) => i.saleId.equals(id))).get();
      for (final item in items) {
        final product = await (_db.select(_db.products)..where((p) => p.id.equals(item.productId))).getSingle();
        final qtyBefore = product.currentQuantity;
        final qtyAfter = qtyBefore + item.quantity;

        await (_db.update(_db.products)..where((p) => p.id.equals(item.productId))).write(
          ProductsCompanion(
            currentQuantity: Value(qtyAfter),
            updatedAt: Value(DateTime.now()),
          ),
        );

        await _db.into(_db.inventoryMovements).insert(
              InventoryMovementsCompanion.insert(
                productId: item.productId,
                movementType: 'customer_return',
                quantity: item.quantity,
                costPrice: Value(item.costPrice),
                quantityBefore: Value(qtyBefore),
                quantityAfter: Value(qtyAfter),
                referenceId: Value(id),
                referenceType: const Value('sale_cancel'),
                reason: Value('إلغاء فاتورة مبيعات #${sale.invoiceNumber}: $reason'),
                userId: Value(userId),
              ),
            );
      }

      // 3. Deduct cash if was paid
      if (sale.paidAmount > 0) {
        final cashBefore = await _db.getCurrentCashBalance();
        await _db.into(_db.cashTransactions).insert(
              CashTransactionsCompanion.insert(
                transactionType: 'cash_out',
                amount: -sale.paidAmount,
                balanceBefore: Value(cashBefore),
                balanceAfter: Value(cashBefore - sale.paidAmount),
                description: 'استرداد نقدي لإلغاء فاتورة #${sale.invoiceNumber}',
                referenceId: Value(id),
                referenceType: const Value('sale_cancel'),
                notes: Value(reason),
                userId: Value(userId),
              ),
            );
      }

      // 4. Revert customer debt if had remaining balance
      if (sale.remainingAmount > 0 && sale.customerId != null) {
        final customer = await (_db.select(_db.customers)..where((c) => c.id.equals(sale.customerId!))).getSingle();
        final balBefore = customer.totalBalance;
        final balAfter = balBefore - sale.remainingAmount;

        await (_db.update(_db.customers)..where((c) => c.id.equals(sale.customerId!))).write(
          CustomersCompanion(
            totalBalance: Value(balAfter),
            lastTransactionAt: Value(DateTime.now()),
          ),
        );

        await _db.into(_db.customerTransactions).insert(
              CustomerTransactionsCompanion.insert(
                customerId: sale.customerId!,
                transactionType: 'return',
                amount: -sale.remainingAmount,
                balanceBefore: Value(balBefore),
                balanceAfter: Value(balAfter),
                referenceId: Value(id),
                referenceType: const Value('sale_cancel'),
                notes: Value('إلغاء متبقي فاتورة #${sale.invoiceNumber}'),
                userId: Value(userId),
              ),
            );
      }

      return true;
    });
  }
}
