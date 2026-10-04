import '../../domain/entities/supplier_entity.dart';
import '../../domain/repositories/suppliers_repository.dart';
import '../datasources/suppliers_local_datasource.dart';

class SuppliersRepositoryImpl implements SuppliersRepository {
  final SuppliersLocalDatasource _datasource;
  SuppliersRepositoryImpl(this._datasource);

  @override
  Future<List<SupplierEntity>> getAll({String? search, int page = 1, int pageSize = 50}) =>
      _datasource.getAll(search: search, page: page, pageSize: pageSize);

  @override
  Future<SupplierEntity?> getById(int id) => _datasource.getById(id);

  @override
  Future<int> create(SupplierEntity supplier) => _datasource.create(supplier);

  @override
  Future<bool> update(SupplierEntity supplier) => _datasource.update(supplier);

  @override
  Future<bool> delete(int id) => _datasource.delete(id);

  @override
  Future<List<SupplierTransactionEntity>> getTransactions(int id) =>
      _datasource.getTransactions(id);

  @override
  Future<void> addPayment({
    required int supplierId,
    required double amount,
    required String notes,
    int? userId,
  }) =>
      _datasource.addPayment(supplierId: supplierId, amount: amount, notes: notes, userId: userId);
}
