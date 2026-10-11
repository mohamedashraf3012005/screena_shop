import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/inventory_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/domain/repositories/products_repository.dart';

abstract class InventoryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<ProductEntity> allProducts;
  final List<InventoryMovementEntity> movements;
  final List<ProductEntity> lowStockProducts;
  final List<StockDamageEntity> damages;
  final List<StockAdjustmentEntity> adjustments;
  final int? filteredProductId;
  final String? filteredProductName;

  InventoryLoaded({
    this.allProducts = const [],
    this.movements = const [],
    this.lowStockProducts = const [],
    this.damages = const [],
    this.adjustments = const [],
    this.filteredProductId,
    this.filteredProductName,
  });

  InventoryLoaded copyWith({
    List<ProductEntity>? allProducts,
    List<InventoryMovementEntity>? movements,
    List<ProductEntity>? lowStockProducts,
    List<StockDamageEntity>? damages,
    List<StockAdjustmentEntity>? adjustments,
    int? filteredProductId,
    String? filteredProductName,
    bool clearProductFilter = false,
  }) {
    return InventoryLoaded(
      allProducts: allProducts ?? this.allProducts,
      movements: movements ?? this.movements,
      lowStockProducts: lowStockProducts ?? this.lowStockProducts,
      damages: damages ?? this.damages,
      adjustments: adjustments ?? this.adjustments,
      filteredProductId: clearProductFilter
          ? null
          : (filteredProductId ?? this.filteredProductId),
      filteredProductName: clearProductFilter
          ? null
          : (filteredProductName ?? this.filteredProductName),
    );
  }

  @override
  List<Object?> get props => [
        allProducts,
        movements,
        lowStockProducts,
        damages,
        adjustments,
        filteredProductId,
        filteredProductName,
      ];
}

class InventoryError extends InventoryState {
  final String message;
  InventoryError(this.message);
  @override
  List<Object?> get props => [message];
}

class InventoryCubit extends Cubit<InventoryState> {
  final InventoryRepository _repository;
  final ProductsRepository _productsRepository;

  InventoryCubit(this._repository, this._productsRepository)
      : super(InventoryInitial());

  Future<void> loadInventoryData({
    int? productId,
    String? productName,
    String? search,
  }) async {
    emit(InventoryLoading());
    try {
      final movements = await _repository.getMovements(productId: productId);
      final lowStock = await _repository.getLowStockProducts();
      final damages = await _repository.getDamages();
      final adjustments = await _repository.getAdjustments();
      final allProducts = await _productsRepository.getAll(
        search: search,
        pageSize: 10000,
      );
      emit(InventoryLoaded(
        allProducts: allProducts,
        movements: movements,
        lowStockProducts: lowStock,
        damages: damages,
        adjustments: adjustments,
        filteredProductId: productId,
        filteredProductName: productName,
      ));
    } catch (e) {
      emit(InventoryError('حدث خطأ أثناء تحميل بيانات المخزون'));
    }
  }

  Future<void> filterMovementsByProduct(
    int? productId, [
    String? productName,
  ]) async {
    if (state is! InventoryLoaded) return;
    final currentState = state as InventoryLoaded;
    try {
      final movements = await _repository.getMovements(productId: productId);
      emit(currentState.copyWith(
        movements: movements,
        filteredProductId: productId,
        filteredProductName: productName,
        clearProductFilter: productId == null,
      ));
    } catch (e) {
      emit(InventoryError('حدث خطأ أثناء تصفية حركات المخزون'));
    }
  }

  Future<bool> recordDamage({
    required int productId,
    required double quantity,
    required String reason,
    String? notes,
    int? userId,
  }) async {
    try {
      await _repository.recordDamage(
        productId: productId,
        quantity: quantity,
        reason: reason,
        notes: notes,
        userId: userId,
      );
      await loadInventoryData();
      return true;
    } catch (e) {
      emit(InventoryError('حدث خطأ أثناء تسجيل الهالك'));
      return false;
    }
  }

  Future<bool> createAdjustment({
    required String notes,
    required List<Map<String, dynamic>> items,
    int? userId,
  }) async {
    try {
      await _repository.createAdjustment(
        notes: notes,
        items: items,
        userId: userId,
      );
      await loadInventoryData();
      return true;
    } catch (e) {
      emit(InventoryError('حدث خطأ أثناء إنشاء محضر الجرد'));
      return false;
    }
  }

  Future<bool> approveAdjustment(int adjustmentId) async {
    try {
      await _repository.approveAdjustment(adjustmentId);
      await loadInventoryData();
      return true;
    } catch (e) {
      emit(InventoryError('حدث خطأ أثناء اعتماد الجرد الفعلي'));
      return false;
    }
  }

  Future<bool> manualStockAdjustment({
    required int productId,
    required double quantityDelta,
    required String reason,
    String? notes,
    int? userId,
    double? newCostPrice,
  }) async {
    try {
      final success = await _repository.manualStockAdjustment(
        productId: productId,
        quantityDelta: quantityDelta,
        reason: reason,
        notes: notes,
        userId: userId,
        newCostPrice: newCostPrice,
      );
      if (success) {
        await loadInventoryData();
      }
      return success;
    } catch (e) {
      emit(InventoryError('حدث خطأ أثناء تعديل المخزون يدوياً'));
      return false;
    }
  }
}

