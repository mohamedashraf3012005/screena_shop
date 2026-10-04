import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customers_repository.dart';
import '../datasources/customers_local_datasource.dart';

class CustomersRepositoryImpl implements CustomersRepository {
  final CustomersLocalDatasource _ds;
  CustomersRepositoryImpl(this._ds);
  @override
  Future<List<CustomerEntity>> getAll({String? search, int page = 1, int pageSize = 50}) =>
      _ds.getAll(search: search, page: page, pageSize: pageSize);
  @override
  Future<CustomerEntity?> getById(int id) => _ds.getById(id);
  @override
  Future<int> create(CustomerEntity customer) => _ds.create(customer);
  @override
  Future<void> update(CustomerEntity customer) => _ds.update(customer);
  @override
  Future<void> delete(int id) => _ds.delete(id);
  @override
  Future<List<CustomerTransactionEntity>> getTransactions(int customerId) =>
      _ds.getTransactions(customerId);
  @override
  Future<void> addPayment({required int customerId, required double amount, required String notes, required int? userId}) =>
      _ds.addPayment(customerId: customerId, amount: amount, notes: notes, userId: userId);
}
