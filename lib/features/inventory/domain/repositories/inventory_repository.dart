import '../entities/inventory_entity.dart';
import '../../../products/domain/entities/product_entity.dart';

abstract class InventoryRepository {
  Future<List<InventoryMovementEntity>> getMovements({int? productId, int page = 1, int pageSize = 50});
  Future<List<StockDamageEntity>> getDamages();
  Future<int> recordDamage({
    required int productId,
    required double quantity,
    required String reason,
    String? notes,
    int? userId,
  });
  Future<List<StockAdjustmentEntity>> getAdjustments();
  Future<int> createAdjustment({
    required String notes,
    required List<Map<String, dynamic>> items,
    int? userId,
  });
  Future<bool> approveAdjustment(int adjustmentId);
  Future<List<ProductEntity>> getLowStockProducts();
}
