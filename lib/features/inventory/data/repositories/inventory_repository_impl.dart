import '../../domain/entities/inventory_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../datasources/inventory_local_datasource.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryLocalDatasource _datasource;
  InventoryRepositoryImpl(this._datasource);

  @override
  Future<List<InventoryMovementEntity>> getMovements({int? productId, int page = 1, int pageSize = 50}) =>
      _datasource.getMovements(productId: productId, page: page, pageSize: pageSize);

  @override
  Future<List<StockDamageEntity>> getDamages() => _datasource.getDamages();

  @override
  Future<int> recordDamage({
    required int productId,
    required double quantity,
    required String reason,
    String? notes,
    int? userId,
  }) =>
      _datasource.recordDamage(
        productId: productId,
        quantity: quantity,
        reason: reason,
        notes: notes,
        userId: userId,
      );

  @override
  Future<List<StockAdjustmentEntity>> getAdjustments() => _datasource.getAdjustments();

  @override
  Future<int> createAdjustment({
    required String notes,
    required List<Map<String, dynamic>> items,
    int? userId,
  }) =>
      _datasource.createAdjustment(notes: notes, items: items, userId: userId);

  @override
  Future<bool> approveAdjustment(int adjustmentId) => _datasource.approveAdjustment(adjustmentId);

  @override
  Future<List<ProductEntity>> getLowStockProducts() => _datasource.getLowStockProducts();

  @override
  Future<bool> manualStockAdjustment({
    required int productId,
    required double quantityDelta,
    required String reason,
    String? notes,
    int? userId,
    double? newCostPrice,
  }) =>
      _datasource.manualStockAdjustment(
        productId: productId,
        quantityDelta: quantityDelta,
        reason: reason,
        notes: notes,
        userId: userId,
        newCostPrice: newCostPrice,
      );
}
