import '../entities/purchase_entity.dart';

abstract class PurchasesRepository {
  Future<List<PurchaseEntity>> getAllPurchases({
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
    int? supplierId,
    int page = 1,
    int pageSize = 50,
  });
  Future<PurchaseEntity?> getPurchaseById(int id);
  Future<int> createPurchase({
    required PurchaseEntity purchase,
    required List<PurchaseItemEntity> items,
  });
  Future<bool> cancelPurchase({required int id, required String reason, int? userId});
}
