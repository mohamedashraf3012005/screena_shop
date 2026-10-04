import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customers_repository.dart';

abstract class CustomersState extends Equatable {
  @override List<Object?> get props => [];
}
class CustomersInitial extends CustomersState {}
class CustomersLoading extends CustomersState {}
class CustomersLoaded extends CustomersState {
  final List<CustomerEntity> customers;
  CustomersLoaded(this.customers);
  @override List<Object?> get props => [customers];
}
class CustomersError extends CustomersState {
  final String message;
  CustomersError(this.message);
  @override List<Object?> get props => [message];
}

class CustomersCubit extends Cubit<CustomersState> {
  final CustomersRepository _repository;
  CustomersCubit(this._repository) : super(CustomersInitial());

  Future<void> loadCustomers({String? search}) async {
    emit(CustomersLoading());
    try {
      final customers = await _repository.getAll(search: search);
      emit(CustomersLoaded(customers));
    } catch (e) {
      emit(CustomersError('حدث خطأ أثناء تحميل العملاء'));
    }
  }

  Future<CustomerEntity?> getById(int id) async {
    try { return await _repository.getById(id); } catch (_) { return null; }
  }

  Future<bool> save(CustomerEntity customer) async {
    try {
      if (customer.id == 0) {
        await _repository.create(customer);
      } else {
        await _repository.update(customer);
      }
      await loadCustomers();
      return true;
    } catch (e) {
      emit(CustomersError('حدث خطأ أثناء حفظ العميل'));
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await _repository.delete(id);
      await loadCustomers();
      return true;
    } catch (e) {
      emit(CustomersError('حدث خطأ أثناء حذف العميل'));
      return false;
    }
  }

  Future<List<CustomerTransactionEntity>> getTransactions(int id) async {
    try { return await _repository.getTransactions(id); } catch (_) { return []; }
  }

  Future<bool> addPayment({required int customerId, required double amount, required String notes, int? userId}) async {
    try {
      await _repository.addPayment(customerId: customerId, amount: amount, notes: notes, userId: userId);
      await loadCustomers();
      return true;
    } catch (e) {
      emit(CustomersError('حدث خطأ أثناء تسجيل الدفع'));
      return false;
    }
  }
}
