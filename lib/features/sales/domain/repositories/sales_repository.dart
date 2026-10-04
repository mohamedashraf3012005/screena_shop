import '../entities/sale_entity.dart';

abstract class SalesRepository {
  Future<List<SaleEntity>> getAllSales({
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
    int? customerId,
    int page = 1,
    int pageSize = 50,
  });
  Future<SaleEntity?> getSaleById(int id);
  Future<int> createSale({
    required SaleEntity sale,
    required List<SaleItemEntity> items,
  });
  Future<bool> cancelSale({required int id, required String reason, int? userId});
}
