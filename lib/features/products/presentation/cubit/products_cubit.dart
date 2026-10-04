import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/products_repository.dart';

// ─── States ───
abstract class ProductsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductsInitial extends ProductsState {}
class ProductsLoading extends ProductsState {}

class ProductsLoaded extends ProductsState {
  final List<ProductEntity> products;
  final int totalCount;
  final int currentPage;
  final String? searchQuery;
  final int? categoryFilter;

  ProductsLoaded({
    required this.products,
    required this.totalCount,
    required this.currentPage,
    this.searchQuery,
    this.categoryFilter,
  });

  @override
  List<Object?> get props => [products, totalCount, currentPage, searchQuery, categoryFilter];
}

class ProductsError extends ProductsState {
  final String message;
  ProductsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProductSaved extends ProductsState {}
class ProductDeleted extends ProductsState {}

// ─── Cubit ───
class ProductsCubit extends Cubit<ProductsState> {
  final ProductsRepository _repository;
  static const int _pageSize = 50;

  ProductsCubit(this._repository) : super(ProductsInitial());

  Future<void> loadProducts({
    String? search,
    int? categoryId,
    int? typeId,
    int page = 1,
  }) async {
    emit(ProductsLoading());
    try {
      final products = await _repository.getAll(
        search: search,
        categoryId: categoryId,
        typeId: typeId,
        page: page,
        pageSize: _pageSize,
      );
      final total = await _repository.getTotalCount();
      emit(ProductsLoaded(
        products: products,
        totalCount: total,
        currentPage: page,
        searchQuery: search,
        categoryFilter: categoryId,
      ));
    } catch (e) {
      emit(ProductsError('حدث خطأ أثناء تحميل المنتجات'));
    }
  }

  Future<ProductEntity?> getById(int id) async {
    try {
      return await _repository.getById(id);
    } catch (e) {
      return null;
    }
  }

  Future<ProductEntity?> searchByBarcode(String barcode) async {
    try {
      return await _repository.getByBarcode(barcode);
    } catch (e) {
      return null;
    }
  }

  Future<bool> saveProduct(ProductEntity product) async {
    try {
      if (product.id == 0) {
        await _repository.create(product);
      } else {
        await _repository.update(product);
      }
      await loadProducts();
      return true;
    } catch (e) {
      emit(ProductsError('حدث خطأ أثناء حفظ المنتج'));
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      await _repository.delete(id);
      await loadProducts();
      return true;
    } catch (e) {
      emit(ProductsError('حدث خطأ أثناء حذف المنتج'));
      return false;
    }
  }

  Future<List<ProductEntity>> getLowStockProducts() async {
    try {
      return await _repository.getLowStockProducts();
    } catch (e) {
      return [];
    }
  }
}
