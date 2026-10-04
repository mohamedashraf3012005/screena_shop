import '../entities/supplier_entity.dart';

abstract class SuppliersRepository {
  Future<List<SupplierEntity>> getAll({String? search, int page = 1, int pageSize = 50});
  Future<SupplierEntity?> getById(int id);
  Future<int> create(SupplierEntity supplier);
  Future<bool> update(SupplierEntity supplier);
  Future<bool> delete(int id);
  Future<List<SupplierTransactionEntity>> getTransactions(int id);
  Future<void> addPayment({required int supplierId, required double amount, required String notes, int? userId});
}
