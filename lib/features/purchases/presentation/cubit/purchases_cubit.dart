import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/purchase_entity.dart';
import '../../domain/repositories/purchases_repository.dart';

abstract class PurchasesState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PurchasesInitial extends PurchasesState {}

class PurchasesLoading extends PurchasesState {}

class PurchasesLoaded extends PurchasesState {
  final List<PurchaseEntity> purchases;
  PurchasesLoaded(this.purchases);
  @override
  List<Object?> get props => [purchases];
}

class PurchasesError extends PurchasesState {
  final String message;
  PurchasesError(this.message);
  @override
  List<Object?> get props => [message];
}

class PurchasesCubit extends Cubit<PurchasesState> {
  final PurchasesRepository _purchasesRepository;

  PurchasesCubit(
    this._purchasesRepository,
  ) : super(PurchasesInitial());

  Future<void> loadPurchases({
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
    int? supplierId,
  }) async {
    emit(PurchasesLoading());
    try {
      final purchases = await _purchasesRepository.getAllPurchases(
        search: search,
        fromDate: fromDate,
        toDate: toDate,
        supplierId: supplierId,
      );
      emit(PurchasesLoaded(purchases));
    } catch (e) {
      emit(PurchasesError('حدث خطأ أثناء تحميل سجل المشتريات'));
    }
  }

  Future<PurchaseEntity?> getPurchaseById(int id) async {
    try {
      return await _purchasesRepository.getPurchaseById(id);
    } catch (_) {
      return null;
    }
  }

  Future<int?> createPurchase({
    required PurchaseEntity purchase,
    required List<PurchaseItemEntity> items,
  }) async {
    try {
      final id = await _purchasesRepository.createPurchase(purchase: purchase, items: items);
      await loadPurchases();
      return id;
    } catch (e) {
      emit(PurchasesError('حدث خطأ أثناء تسجيل فاتورة الشراء'));
      return null;
    }
  }

  Future<bool> cancelPurchase({required int id, required String reason, int? userId}) async {
    try {
      final success = await _purchasesRepository.cancelPurchase(id: id, reason: reason, userId: userId);
      await loadPurchases();
      return success;
    } catch (e) {
      emit(PurchasesError('حدث خطأ أثناء إلغاء فاتورة الشراء'));
      return false;
    }
  }
}
