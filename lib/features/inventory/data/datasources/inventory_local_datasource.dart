import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/inventory_entity.dart';
import '../../../products/domain/entities/product_entity.dart';

class InventoryLocalDatasource {
  final AppDatabase _db;
  InventoryLocalDatasource(this._db);

  Future<List<InventoryMovementEntity>> getMovements({
    int? productId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final query = _db.select(_db.inventoryMovements).join([
      innerJoin(_db.products, _db.products.id.equalsExp(_db.inventoryMovements.productId)),
    ]);

    if (productId != null) {
      query.where(_db.inventoryMovements.productId.equals(productId));
    }

    query.orderBy([OrderingTerm.desc(_db.inventoryMovements.createdAt)]);
    query.limit(pageSize, offset: (page - 1) * pageSize);

    final rows = await query.get();

    return rows.map((row) {
      final mov = row.readTable(_db.inventoryMovements);
      final prod = row.readTable(_db.products);
      return InventoryMovementEntity(
        id: mov.id,
        productId: mov.productId,
        productName: prod.name,
        movementType: mov.movementType,
        quantity: mov.quantity,
        costPrice: mov.costPrice,
        quantityBefore: mov.quantityBefore,
        quantityAfter: mov.quantityAfter,
        referenceId: mov.referenceId,
        referenceType: mov.referenceType,
        reason: mov.reason,
        notes: mov.notes,
        createdAt: mov.createdAt,
      );
    }).toList();
  }

  Future<List<StockDamageEntity>> getDamages() async {
    final rows = await (_db.select(_db.stockDamages)
          ..orderBy([(d) => OrderingTerm.desc(d.createdAt)]))
        .get();

    return rows
        .map((r) => StockDamageEntity(
              id: r.id,
              productId: r.productId,
              productName: r.productName,
              quantity: r.quantity,
              costPrice: r.costPrice,
              totalCost: r.totalCost,
              reason: r.reason,
              notes: r.notes,
              createdAt: r.createdAt,
            ))
        .toList();
  }

  Future<int> recordDamage({
    required int productId,
    required double quantity,
    required String reason,
    String? notes,
    int? userId,
  }) async {
    return await _db.transaction(() async {
      final product = await (_db.select(_db.products)..where((p) => p.id.equals(productId))).getSingle();
      final beforeQty = product.currentQuantity;
      final afterQty = beforeQty - quantity;
      final cost = product.costPrice;
      final totalCost = quantity * cost;

      // Update product current quantity
      await (_db.update(_db.products)..where((p) => p.id.equals(productId))).write(
        ProductsCompanion(
          currentQuantity: Value(afterQty),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // Record damage
      final damageId = await _db.into(_db.stockDamages).insert(
            StockDamagesCompanion.insert(
              productId: productId,
              productName: product.name,
              quantity: quantity,
              costPrice: cost,
              totalCost: totalCost,
              reason: reason,
              notes: Value(notes),
              userId: Value(userId),
            ),
          );

      // Record movement
      await _db.into(_db.inventoryMovements).insert(
            InventoryMovementsCompanion.insert(
              productId: productId,
              movementType: 'damage',
              quantity: -quantity,
              costPrice: Value(cost),
              quantityBefore: Value(beforeQty),
              quantityAfter: Value(afterQty),
              referenceId: Value(damageId),
              referenceType: const Value('damage'),
              reason: Value(reason),
              notes: Value(notes),
              userId: Value(userId),
            ),
          );

      return damageId;
    });
  }

  Future<List<StockAdjustmentEntity>> getAdjustments() async {
    final rows = await (_db.select(_db.stockAdjustments)
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
        .get();

    final List<StockAdjustmentEntity> adjustments = [];
    for (final adj in rows) {
      final items = await (_db.select(_db.stockAdjustmentItems)
            ..where((i) => i.adjustmentId.equals(adj.id)))
          .get();

      adjustments.add(StockAdjustmentEntity(
        id: adj.id,
        adjustmentNumber: adj.adjustmentNumber,
        status: adj.status,
        notes: adj.notes,
        createdAt: adj.createdAt,
        approvedAt: adj.approvedAt,
        items: items
            .map((i) => StockAdjustmentItemEntity(
                  id: i.id,
                  adjustmentId: i.adjustmentId,
                  productId: i.productId,
                  productName: i.productName,
                  systemQuantity: i.systemQuantity,
                  actualQuantity: i.actualQuantity,
                  difference: i.difference,
                ))
            .toList(),
      ));
    }
    return adjustments;
  }

  Future<int> createAdjustment({
    required String notes,
    required List<Map<String, dynamic>> items,
    int? userId,
  }) async {
    return await _db.transaction(() async {
      final adjNumber = 'ADJ-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      final adjId = await _db.into(_db.stockAdjustments).insert(
            StockAdjustmentsCompanion.insert(
              adjustmentNumber: adjNumber,
              status: const Value('draft'),
              notes: Value(notes),
              userId: Value(userId),
            ),
          );

      for (final item in items) {
        await _db.into(_db.stockAdjustmentItems).insert(
              StockAdjustmentItemsCompanion.insert(
                adjustmentId: adjId,
                productId: item['product_id'] as int,
                productName: item['product_name'] as String,
                systemQuantity: (item['system_quantity'] as num).toDouble(),
                actualQuantity: (item['actual_quantity'] as num).toDouble(),
                difference: (item['difference'] as num).toDouble(),
              ),
            );
      }
      return adjId;
    });
  }

  Future<bool> approveAdjustment(int adjustmentId) async {
    return await _db.transaction(() async {
      final items = await (_db.select(_db.stockAdjustmentItems)
            ..where((i) => i.adjustmentId.equals(adjustmentId)))
          .get();

      for (final item in items) {
        final product = await (_db.select(_db.products)..where((p) => p.id.equals(item.productId))).getSingle();
        final beforeQty = product.currentQuantity;
        final afterQty = item.actualQuantity;

        // Update product quantity to match actual count
        await (_db.update(_db.products)..where((p) => p.id.equals(item.productId))).write(
          ProductsCompanion(
            currentQuantity: Value(afterQty),
            updatedAt: Value(DateTime.now()),
          ),
        );

        // Record stock movement
        await _db.into(_db.inventoryMovements).insert(
              InventoryMovementsCompanion.insert(
                productId: item.productId,
                movementType: 'inventory_adj',
                quantity: item.difference,
                costPrice: Value(product.costPrice),
                quantityBefore: Value(beforeQty),
                quantityAfter: Value(afterQty),
                referenceId: Value(adjustmentId),
                referenceType: const Value('adjustment'),
                reason: const Value('تسوية جرد فعلي'),
              ),
            );
      }

      await (_db.update(_db.stockAdjustments)..where((a) => a.id.equals(adjustmentId))).write(
        StockAdjustmentsCompanion(
          status: const Value('approved'),
          approvedAt: Value(DateTime.now()),
        ),
      );

      return true;
    });
  }

  Future<List<ProductEntity>> getLowStockProducts() async {
    final prods = await _db.getLowStockProducts();
    return prods
        .map((p) => ProductEntity(
              id: p.id,
              name: p.name,
              barcode: p.barcode,
              categoryId: p.categoryId,
              productTypeId: p.productTypeId,
              description: p.description,
              unit: p.unit,
              currentQuantity: p.currentQuantity,
              minQuantity: p.minQuantity,
              costPrice: p.costPrice,
              sellPrice: p.sellPrice,
              groupPrice: p.groupPrice,
              groupQuantity: p.groupQuantity,
              weightedAvgCost: p.weightedAvgCost,
              status: p.status,
              createdAt: p.createdAt,
              updatedAt: p.updatedAt,
            ))
        .toList();
  }
}
