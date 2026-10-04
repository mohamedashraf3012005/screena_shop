import '../entities/customer_entity.dart';

abstract class CustomersRepository {
  Future<List<CustomerEntity>> getAll({String? search, int page, int pageSize});
  Future<CustomerEntity?> getById(int id);
  Future<int> create(CustomerEntity customer);
  Future<void> update(CustomerEntity customer);
  Future<void> delete(int id);
  Future<List<CustomerTransactionEntity>> getTransactions(int customerId);
  Future<void> addPayment({
    required int customerId,
    required double amount,
    required String notes,
    required int? userId,
  });
}
