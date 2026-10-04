import '../../domain/entities/purchase_entity.dart';
import '../../domain/repositories/purchases_repository.dart';
import '../datasources/purchases_local_datasource.dart';

class PurchasesRepositoryImpl implements PurchasesRepository {
  final PurchasesLocalDatasource _datasource;
  PurchasesRepositoryImpl(this._datasource);

  @override
  Future<List<PurchaseEntity>> getAllPurchases({
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
    int? supplierId,
    int page = 1,
    int pageSize = 50,
  }) =>
      _datasource.getAllPurchases(
        search: search,
        fromDate: fromDate,
        toDate: toDate,
        supplierId: supplierId,
        page: page,
        pageSize: pageSize,
      );

  @override
  Future<PurchaseEntity?> getPurchaseById(int id) => _datasource.getPurchaseById(id);

  @override
  Future<int> createPurchase({
    required PurchaseEntity purchase,
    required List<PurchaseItemEntity> items,
  }) =>
      _datasource.createPurchase(purchase: purchase, items: items);

  @override
  Future<bool> cancelPurchase({required int id, required String reason, int? userId}) =>
      _datasource.cancelPurchase(id: id, reason: reason, userId: userId);
}
