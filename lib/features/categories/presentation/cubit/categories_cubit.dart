import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/categories_repository.dart';

abstract class CategoriesState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CategoriesInitial extends CategoriesState {}
class CategoriesLoading extends CategoriesState {}

class CategoriesLoaded extends CategoriesState {
  final List<CategoryEntity> categories;
  final List<ProductTypeEntity> types;

  CategoriesLoaded({required this.categories, required this.types});

  @override
  List<Object?> get props => [categories, types];
}

class CategoriesError extends CategoriesState {
  final String message;
  CategoriesError(this.message);
  @override
  List<Object?> get props => [message];
}

class CategoriesCubit extends Cubit<CategoriesState> {
  final CategoriesRepository _repository;

  CategoriesCubit(this._repository) : super(CategoriesInitial());

  Future<void> loadCategories() async {
    emit(CategoriesLoading());
    try {
      final categories = await _repository.getAllCategories();
      final types = await _repository.getAllTypes();
      emit(CategoriesLoaded(categories: categories, types: types));
    } catch (e) {
      emit(CategoriesError('حدث خطأ أثناء تحميل التصنيفات'));
    }
  }

  Future<bool> createCategory(String name, String? description) async {
    try {
      await _repository.createCategory(name, description);
      await loadCategories();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<int?> createCategoryAndReturnId(String name, String? description) async {
    try {
      final id = await _repository.createCategory(name, description);
      await loadCategories();
      return id;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateCategory(int id, String name, String? description) async {
    try {
      await _repository.updateCategory(id, name, description);
      await loadCategories();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      await _repository.deleteCategory(id);
      await loadCategories();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createType(int categoryId, String name, String? description) async {
    try {
      await _repository.createType(categoryId, name, description);
      await loadCategories();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<int?> createTypeAndReturnId(int categoryId, String name, String? description) async {
    try {
      final id = await _repository.createType(categoryId, name, description);
      await loadCategories();
      return id;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateType(int id, String name, String? description) async {
    try {
      await _repository.updateType(id, name, description);
      await loadCategories();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteType(int id) async {
    try {
      await _repository.deleteType(id);
      await loadCategories();
      return true;
    } catch (e) {
      return false;
    }
  }
}
