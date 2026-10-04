import '../entities/category_entity.dart';

abstract class CategoriesRepository {
  Future<List<CategoryEntity>> getAllCategories();
  Future<List<ProductTypeEntity>> getAllTypes({int? categoryId});
  Future<int> createCategory(String name, String? description);
  Future<void> updateCategory(int id, String name, String? description);
  Future<void> deleteCategory(int id);
  Future<int> createType(int categoryId, String name, String? description);
  Future<void> updateType(int id, String name, String? description);
  Future<void> deleteType(int id);
}
