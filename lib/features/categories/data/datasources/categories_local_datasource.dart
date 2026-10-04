import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/category_entity.dart';

class CategoriesLocalDatasource {
  final AppDatabase _db;
  CategoriesLocalDatasource(this._db);

  Future<List<CategoryEntity>> getAllCategories() async {
    final rows = await _db.customSelect(
      '''SELECT c.*, COUNT(p.id) as product_count
         FROM categories c
         LEFT JOIN products p ON p.category_id = c.id AND p.status = 'active'
         WHERE c.is_active = 1
         GROUP BY c.id
         ORDER BY c.name''',
      readsFrom: {_db.categories, _db.products},
    ).get();

    return rows.map((r) => CategoryEntity(
          id: r.read<int>('id'),
          name: r.read<String>('name'),
          description: r.readNullable<String>('description'),
          isActive: r.read<bool>('is_active'),
          productCount: r.read<int>('product_count'),
          createdAt: r.read<DateTime>('created_at'),
        )).toList();
  }

  Future<List<ProductTypeEntity>> getAllTypes({int? categoryId}) async {
    final whereClause =
        categoryId != null ? 'AND t.category_id = $categoryId' : '';

    final rows = await _db.customSelect(
      '''SELECT t.*, c.name as cat_name, COUNT(p.id) as product_count
         FROM product_types t
         JOIN categories c ON c.id = t.category_id
         LEFT JOIN products p ON p.product_type_id = t.id AND p.status = 'active'
         WHERE t.is_active = 1 $whereClause
         GROUP BY t.id
         ORDER BY c.name, t.name''',
      readsFrom: {_db.productTypes, _db.categories, _db.products},
    ).get();

    return rows.map((r) => ProductTypeEntity(
          id: r.read<int>('id'),
          categoryId: r.read<int>('category_id'),
          categoryName: r.read<String>('cat_name'),
          name: r.read<String>('name'),
          description: r.readNullable<String>('description'),
          isActive: r.read<bool>('is_active'),
          productCount: r.read<int>('product_count'),
          createdAt: r.read<DateTime>('created_at'),
        )).toList();
  }

  Future<int> createCategory(String name, String? description) async {
    return await _db.into(_db.categories).insert(
          CategoriesCompanion.insert(
              name: name, description: Value(description)),
        );
  }

  Future<void> updateCategory(int id, String name, String? description) async {
    await (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
          name: Value(name), description: Value(description)),
    );
  }

  Future<void> deleteCategory(int id) async {
    await (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      const CategoriesCompanion(isActive: Value(false)),
    );
  }

  Future<int> createType(
      int categoryId, String name, String? description) async {
    return await _db.into(_db.productTypes).insert(
          ProductTypesCompanion.insert(
            categoryId: categoryId,
            name: name,
            description: Value(description),
          ),
        );
  }

  Future<void> updateType(int id, String name, String? description) async {
    await (_db.update(_db.productTypes)..where((t) => t.id.equals(id))).write(
      ProductTypesCompanion(
          name: Value(name), description: Value(description)),
    );
  }

  Future<void> deleteType(int id) async {
    await (_db.update(_db.productTypes)..where((t) => t.id.equals(id))).write(
      const ProductTypesCompanion(isActive: Value(false)),
    );
  }
}
