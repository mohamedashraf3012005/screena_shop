import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/product_entity.dart';

class ProductsLocalDatasource {
  final AppDatabase _db;
  ProductsLocalDatasource(this._db);

  Future<List<ProductEntity>> getAll({
    String? search,
    int? categoryId,
    int? typeId,
    String? status = 'active',
    int page = 1,
    int pageSize = 50,
  }) async {
    final query = _db.select(_db.products).join([
      leftOuterJoin(_db.categories,
          _db.categories.id.equalsExp(_db.products.categoryId)),
      leftOuterJoin(_db.productTypes,
          _db.productTypes.id.equalsExp(_db.products.productTypeId)),
    ]);

    if (search != null && search.isNotEmpty) {
      query.where(_db.products.name.contains(search) |
          _db.products.barcode.contains(search));
    }
    if (categoryId != null) {
      query.where(_db.products.categoryId.equals(categoryId));
    }
    if (typeId != null) {
      query.where(_db.products.productTypeId.equals(typeId));
    }
    if (status != null && status != 'all') {
      query.where(_db.products.status.equals(status));
    }

    query.orderBy([OrderingTerm.desc(_db.products.updatedAt)]);
    query.limit(pageSize, offset: (page - 1) * pageSize);

    final rows = await query.get();
    return rows.map((row) {
      final p = row.readTable(_db.products);
      final cat = row.readTableOrNull(_db.categories);
      final type = row.readTableOrNull(_db.productTypes);
      return _toEntity(p, categoryName: cat?.name, typeName: type?.name);
    }).toList();
  }

  Future<ProductEntity?> getById(int id) async {
    final query = _db.select(_db.products).join([
      leftOuterJoin(_db.categories,
          _db.categories.id.equalsExp(_db.products.categoryId)),
      leftOuterJoin(_db.productTypes,
          _db.productTypes.id.equalsExp(_db.products.productTypeId)),
    ])
      ..where(_db.products.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;
    final p = row.readTable(_db.products);
    final cat = row.readTableOrNull(_db.categories);
    final type = row.readTableOrNull(_db.productTypes);
    return _toEntity(p, categoryName: cat?.name, typeName: type?.name);
  }

  Future<ProductEntity?> getByBarcode(String barcode) async {
    final query = _db.select(_db.products).join([
      leftOuterJoin(_db.categories,
          _db.categories.id.equalsExp(_db.products.categoryId)),
      leftOuterJoin(_db.productTypes,
          _db.productTypes.id.equalsExp(_db.products.productTypeId)),
    ])
      ..where(_db.products.barcode.equals(barcode));

    final row = await query.getSingleOrNull();
    if (row == null) return null;
    final p = row.readTable(_db.products);
    final cat = row.readTableOrNull(_db.categories);
    final type = row.readTableOrNull(_db.productTypes);
    return _toEntity(p, categoryName: cat?.name, typeName: type?.name);
  }

  Future<int> create(ProductEntity entity) async {
    return await _db.into(_db.products).insert(ProductsCompanion.insert(
          name: entity.name,
          barcode: Value(entity.barcode),
          categoryId: Value(entity.categoryId),
          productTypeId: Value(entity.productTypeId),
          description: Value(entity.description),
          unit: Value(entity.unit),
          currentQuantity: Value(entity.currentQuantity),
          minQuantity: Value(entity.minQuantity),
          costPrice: Value(entity.costPrice),
          sellPrice: Value(entity.sellPrice),
          groupPrice: Value(entity.groupPrice),
          groupQuantity: Value(entity.groupQuantity),
          weightedAvgCost: Value(entity.costPrice),
          status: Value(entity.status),
        ));
  }

  Future<void> update(ProductEntity entity) async {
    await (_db.update(_db.products)..where((p) => p.id.equals(entity.id)))
        .write(ProductsCompanion(
      name: Value(entity.name),
      barcode: Value(entity.barcode),
      categoryId: Value(entity.categoryId),
      productTypeId: Value(entity.productTypeId),
      description: Value(entity.description),
      unit: Value(entity.unit),
      minQuantity: Value(entity.minQuantity),
      costPrice: Value(entity.costPrice),
      sellPrice: Value(entity.sellPrice),
      groupPrice: Value(entity.groupPrice),
      groupQuantity: Value(entity.groupQuantity),
      status: Value(entity.status),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> delete(int id) async {
    // التحقق هل للمنتج فواتير مبيعات أو مشتريات أو مرتجعات
    final hasSales = (await (_db.select(_db.saleItems)..where((s) => s.productId.equals(id))).get()).isNotEmpty;
    final hasPurchases = (await (_db.select(_db.purchaseItems)..where((p) => p.productId.equals(id))).get()).isNotEmpty;
    final hasReturns = (await (_db.select(_db.returnItems)..where((r) => r.productId.equals(id))).get()).isNotEmpty;

    if (!hasSales && !hasPurchases && !hasReturns) {
      // حذف الحركات المرتبطة والجرد والهالك لحذف المنتج نهائياً من الأساس
      await (_db.delete(_db.stockAdjustmentItems)..where((a) => a.productId.equals(id))).go();
      await (_db.delete(_db.stockDamages)..where((d) => d.productId.equals(id))).go();
      await (_db.delete(_db.inventoryMovements)..where((m) => m.productId.equals(id))).go();
      await (_db.delete(_db.products)..where((p) => p.id.equals(id))).go();
    } else {
      // تعطيل المنتج فقط للحفاظ على نزاهة سجلات الفواتير السابقة
      await (_db.update(_db.products)..where((p) => p.id.equals(id)))
          .write(const ProductsCompanion(status: Value('inactive')));
    }
  }

  Future<List<ProductEntity>> getLowStockProducts() async {
    final rows = await _db.customSelect(
      '''SELECT p.*, c.name as cat_name, t.name as type_name
         FROM products p
         LEFT JOIN categories c ON c.id = p.category_id
         LEFT JOIN product_types t ON t.id = p.product_type_id
         WHERE p.status = 'active' AND p.current_quantity <= p.min_quantity
         ORDER BY p.current_quantity ASC
         LIMIT 100''',
      readsFrom: {_db.products, _db.categories, _db.productTypes},
    ).get();

    return rows.map((row) {
      return ProductEntity(
        id: row.read<int>('id'),
        name: row.read<String>('name'),
        barcode: row.readNullable<String>('barcode'),
        categoryId: row.readNullable<int>('category_id'),
        categoryName: row.readNullable<String>('cat_name'),
        productTypeId: row.readNullable<int>('product_type_id'),
        productTypeName: row.readNullable<String>('type_name'),
        unit: row.read<String>('unit'),
        currentQuantity: row.read<double>('current_quantity'),
        minQuantity: row.read<double>('min_quantity'),
        costPrice: row.read<double>('cost_price'),
        sellPrice: row.read<double>('sell_price'),
        groupPrice: row.read<double>('group_price'),
        groupQuantity: row.read<double>('group_quantity'),
        weightedAvgCost: row.read<double>('weighted_avg_cost'),
        status: row.read<String>('status'),
        createdAt: row.read<DateTime>('created_at'),
        updatedAt: row.read<DateTime>('updated_at'),
      );
    }).toList();
  }

  Future<int> getTotalCount() async {
    final result = await _db
        .customSelect('SELECT COUNT(*) as count FROM products WHERE status = \'active\'',
            readsFrom: {_db.products})
        .getSingle();
    return result.read<int>('count');
  }

  // تحديث الكمية ومتوسط التكلفة (يستخدم داخلياً)
  Future<void> updateQuantityAndCost({
    required int productId,
    required double quantityDelta,
    double? newCostPrice,
  }) async {
    final product = await (_db.select(_db.products)
          ..where((p) => p.id.equals(productId)))
        .getSingle();

    final newQuantity = product.currentQuantity + quantityDelta;

    double newWeightedAvg = product.weightedAvgCost;
    if (newCostPrice != null && quantityDelta > 0) {
      // حساب المتوسط المرجح
      final totalExistingCost = product.currentQuantity * product.weightedAvgCost;
      final newCost = quantityDelta * newCostPrice;
      final totalQuantity = product.currentQuantity + quantityDelta;
      if (totalQuantity > 0) {
        newWeightedAvg = (totalExistingCost + newCost) / totalQuantity;
      }
    }

    await (_db.update(_db.products)..where((p) => p.id.equals(productId))).write(
      ProductsCompanion(
        currentQuantity: Value(newQuantity),
        weightedAvgCost: Value(newWeightedAvg),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  ProductEntity _toEntity(
    Product p, {
    String? categoryName,
    String? typeName,
  }) {
    return ProductEntity(
      id: p.id,
      name: p.name,
      barcode: p.barcode,
      categoryId: p.categoryId,
      categoryName: categoryName,
      productTypeId: p.productTypeId,
      productTypeName: typeName,
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
    );
  }
}
