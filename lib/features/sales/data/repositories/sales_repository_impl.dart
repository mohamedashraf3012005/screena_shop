import '../../domain/entities/sale_entity.dart';
import '../../domain/repositories/sales_repository.dart';
import '../datasources/sales_local_datasource.dart';

class SalesRepositoryImpl implements SalesRepository {
  final SalesLocalDatasource _datasource;
  SalesRepositoryImpl(this._datasource);

  @override
  Future<List<SaleEntity>> getAllSales({
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
    int? customerId,
    int page = 1,
    int pageSize = 50,
  }) =>
      _datasource.getAllSales(
        search: search,
        fromDate: fromDate,
        toDate: toDate,
        customerId: customerId,
        page: page,
        pageSize: pageSize,
      );

  @override
  Future<SaleEntity?> getSaleById(int id) => _datasource.getSaleById(id);

  @override
  Future<int> createSale({
    required SaleEntity sale,
    required List<SaleItemEntity> items,
  }) =>
      _datasource.createSale(sale: sale, items: items);

  @override
  Future<bool> cancelSale({required int id, required String reason, int? userId}) =>
      _datasource.cancelSale(id: id, reason: reason, userId: userId);
}
