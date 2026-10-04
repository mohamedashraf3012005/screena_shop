import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/categories_repository.dart';
import '../datasources/categories_local_datasource.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  final CategoriesLocalDatasource _datasource;
  CategoriesRepositoryImpl(this._datasource);

  @override
  Future<List<CategoryEntity>> getAllCategories() => _datasource.getAllCategories();
  @override
  Future<List<ProductTypeEntity>> getAllTypes({int? categoryId}) =>
      _datasource.getAllTypes(categoryId: categoryId);
  @override
  Future<int> createCategory(String name, String? description) =>
      _datasource.createCategory(name, description);
  @override
  Future<void> updateCategory(int id, String name, String? description) =>
      _datasource.updateCategory(id, name, description);
  @override
  Future<void> deleteCategory(int id) => _datasource.deleteCategory(id);
  @override
  Future<int> createType(int categoryId, String name, String? description) =>
      _datasource.createType(categoryId, name, description);
  @override
  Future<void> updateType(int id, String name, String? description) =>
      _datasource.updateType(id, name, description);
  @override
  Future<void> deleteType(int id) => _datasource.deleteType(id);
}
