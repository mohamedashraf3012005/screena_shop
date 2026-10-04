import '../entities/product_entity.dart';

abstract class ProductsRepository {
  Future<List<ProductEntity>> getAll({
    String? search,
    int? categoryId,
    int? typeId,
    String? status,
    int page,
    int pageSize,
  });

  Future<ProductEntity?> getById(int id);
  Future<ProductEntity?> getByBarcode(String barcode);
  Future<int> create(ProductEntity product);
  Future<void> update(ProductEntity product);
  Future<void> delete(int id);
  Future<List<ProductEntity>> getLowStockProducts();
  Future<int> getTotalCount();
}
