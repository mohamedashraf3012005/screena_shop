import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/products_repository.dart';
import '../datasources/products_local_datasource.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  final ProductsLocalDatasource _datasource;
  ProductsRepositoryImpl(this._datasource);

  @override
  Future<List<ProductEntity>> getAll({
    String? search,
    int? categoryId,
    int? typeId,
    String? status,
    int page = 1,
    int pageSize = 50,
  }) =>
      _datasource.getAll(
        search: search,
        categoryId: categoryId,
        typeId: typeId,
        status: status,
        page: page,
        pageSize: pageSize,
      );

  @override
  Future<ProductEntity?> getById(int id) => _datasource.getById(id);

  @override
  Future<ProductEntity?> getByBarcode(String barcode) =>
      _datasource.getByBarcode(barcode);

  @override
  Future<int> create(ProductEntity product) => _datasource.create(product);

  @override
  Future<void> update(ProductEntity product) => _datasource.update(product);

  @override
  Future<void> delete(int id) => _datasource.delete(id);

  @override
  Future<List<ProductEntity>> getLowStockProducts() =>
      _datasource.getLowStockProducts();

  @override
  Future<int> getTotalCount() => _datasource.getTotalCount();
}
