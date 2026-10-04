import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/supplier_entity.dart';
import '../../domain/repositories/suppliers_repository.dart';

abstract class SuppliersState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SuppliersInitial extends SuppliersState {}

class SuppliersLoading extends SuppliersState {}

class SuppliersLoaded extends SuppliersState {
  final List<SupplierEntity> suppliers;
  SuppliersLoaded(this.suppliers);
  @override
  List<Object?> get props => [suppliers];
}

class SuppliersError extends SuppliersState {
  final String message;
  SuppliersError(this.message);
  @override
  List<Object?> get props => [message];
}

class SuppliersCubit extends Cubit<SuppliersState> {
  final SuppliersRepository _repository;
  SuppliersCubit(this._repository) : super(SuppliersInitial());

  Future<void> loadSuppliers({String? search}) async {
    emit(SuppliersLoading());
    try {
      final suppliers = await _repository.getAll(search: search);
      emit(SuppliersLoaded(suppliers));
    } catch (e) {
      emit(SuppliersError('حدث خطأ أثناء تحميل بيانات الموردين'));
    }
  }

  Future<SupplierEntity?> getById(int id) async {
    try {
      return await _repository.getById(id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> save(SupplierEntity supplier) async {
    try {
      if (supplier.id == 0) {
        await _repository.create(supplier);
      } else {
        await _repository.update(supplier);
      }
      await loadSuppliers();
      return true;
    } catch (e) {
      emit(SuppliersError('حدث خطأ أثناء حفظ بيانات المورد'));
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await _repository.delete(id);
      await loadSuppliers();
      return true;
    } catch (e) {
      emit(SuppliersError('حدث خطأ أثناء حذف المورد'));
      return false;
    }
  }

  Future<List<SupplierTransactionEntity>> getTransactions(int id) async {
    try {
      return await _repository.getTransactions(id);
    } catch (_) {
      return [];
    }
  }

  Future<bool> addPayment({
    required int supplierId,
    required double amount,
    required String notes,
    int? userId,
  }) async {
    try {
      await _repository.addPayment(
        supplierId: supplierId,
        amount: amount,
        notes: notes,
        userId: userId,
      );
      await loadSuppliers();
      return true;
    } catch (e) {
      emit(SuppliersError('حدث خطأ أثناء تسجيل سداد المورد'));
      return false;
    }
  }
}
