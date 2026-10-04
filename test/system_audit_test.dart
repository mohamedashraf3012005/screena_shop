import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:escrena/core/database/app_database.dart';
import 'package:escrena/features/categories/data/datasources/categories_local_datasource.dart';
import 'package:escrena/features/categories/data/repositories/categories_repository_impl.dart';
import 'package:escrena/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:escrena/features/products/data/datasources/products_local_datasource.dart';
import 'package:escrena/features/products/data/repositories/products_repository_impl.dart';
import 'package:escrena/features/products/presentation/cubit/products_cubit.dart';
import 'package:escrena/features/products/domain/entities/product_entity.dart';
import 'package:escrena/features/sales/data/datasources/sales_local_datasource.dart';
import 'package:escrena/features/sales/data/repositories/sales_repository_impl.dart';
import 'package:escrena/features/sales/presentation/cubit/sales_cubit.dart';
import 'package:escrena/features/customers/data/datasources/customers_local_datasource.dart';
import 'package:escrena/features/customers/data/repositories/customers_repository_impl.dart';
import 'package:escrena/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:escrena/features/customers/domain/entities/customer_entity.dart';
import 'package:escrena/features/expenses/data/datasources/expenses_local_datasource.dart';
import 'package:escrena/features/expenses/data/repositories/expenses_repository_impl.dart';
import 'package:escrena/features/expenses/presentation/cubit/expenses_cubit.dart';
import 'package:escrena/features/expenses/domain/entities/expense_entity.dart';
import 'package:escrena/features/inventory/data/datasources/inventory_local_datasource.dart';
import 'package:escrena/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:escrena/features/inventory/presentation/cubit/inventory_cubit.dart';

void main() {
  late AppDatabase db;
  late CategoriesLocalDatasource catDatasource;
  late CategoriesCubit catCubit;
  late ProductsLocalDatasource prodDatasource;
  late ProductsCubit prodCubit;
  late SalesLocalDatasource salesDatasource;
  late SalesCubit salesCubit;
  late CustomersLocalDatasource custDatasource;
  late CustomersCubit custCubit;
  late ExpensesLocalDatasource expDatasource;
  late ExpensesCubit expCubit;
  late InventoryCubit invCubit;

  setUp(() async {
    // Open in-memory database
    db = AppDatabase.forTesting(NativeDatabase.memory());

    catDatasource = CategoriesLocalDatasource(db);
    final catRepo = CategoriesRepositoryImpl(catDatasource);
    catCubit = CategoriesCubit(catRepo);

    prodDatasource = ProductsLocalDatasource(db);
    final prodRepo = ProductsRepositoryImpl(prodDatasource);
    prodCubit = ProductsCubit(prodRepo);

    salesDatasource = SalesLocalDatasource(db);
    final salesRepo = SalesRepositoryImpl(salesDatasource);
    salesCubit = SalesCubit(salesRepo, prodRepo);

    custDatasource = CustomersLocalDatasource(db);
    final custRepo = CustomersRepositoryImpl(custDatasource);
    custCubit = CustomersCubit(custRepo);

    expDatasource = ExpensesLocalDatasource(db);
    final expRepo = ExpensesRepositoryImpl(expDatasource);
    expCubit = ExpensesCubit(expRepo);

    final invDatasource = InventoryLocalDatasource(db);
    final invRepo = InventoryRepositoryImpl(invDatasource);
    invCubit = InventoryCubit(invRepo, prodRepo);
  });

  tearDown(() async {
    await db.close();
  });

  test('Comprehensive Test: Categories and Product Types lifecycle', () async {
    // 1. Initially load categories
    await catCubit.loadCategories();
    expect(catCubit.state, isA<CategoriesLoaded>());
    var loaded = catCubit.state as CategoriesLoaded;
    final initialCatCount = loaded.categories.length;

    // 2. Create Category
    final created = await catCubit.createCategory('قطع غيار', 'قطع غيار متنوعة');
    expect(created, isTrue);

    loaded = catCubit.state as CategoriesLoaded;
    expect(loaded.categories.length, equals(initialCatCount + 1));
    final cat = loaded.categories.firstWhere((c) => c.name == 'قطع غيار');
    expect(cat.name, equals('قطع غيار'));
    expect(cat.description, equals('قطع غيار متنوعة'));
    expect(cat.productCount, equals(0));

    // 3. Update Category
    final updated = await catCubit.updateCategory(cat.id, 'قطع غيار وكهرباء', 'وصف معدل');
    expect(updated, isTrue);
    loaded = catCubit.state as CategoriesLoaded;
    expect(loaded.categories.firstWhere((c) => c.id == cat.id).name, equals('قطع غيار وكهرباء'));

    // 4. Create Product Type under category
    final typeId = await catCubit.createTypeAndReturnId(cat.id, 'شاشات', 'شاشات سمارت');
    expect(typeId, isNotNull);
    loaded = catCubit.state as CategoriesLoaded;
    expect(loaded.types.length, equals(1));
    final type = loaded.types.first;
    expect(type.id, equals(typeId));
    expect(type.name, equals('شاشات'));
    expect(type.categoryId, equals(cat.id));

    // 5. Update Product Type
    final typeUpdated = await catCubit.updateType(type.id, 'شاشات وتلفزيونات', 'وصف جديد');
    expect(typeUpdated, isTrue);
    loaded = catCubit.state as CategoriesLoaded;
    expect(loaded.types.first.name, equals('شاشات وتلفزيونات'));

    // 6. Delete Type
    final typeDeleted = await catCubit.deleteType(type.id);
    expect(typeDeleted, isTrue);
    loaded = catCubit.state as CategoriesLoaded;
    expect(loaded.types.length, equals(0));

    // 7. Delete Category
    final catDeleted = await catCubit.deleteCategory(cat.id);
    expect(catDeleted, isTrue);
    loaded = catCubit.state as CategoriesLoaded;
    expect(loaded.categories.any((c) => c.id == cat.id), isFalse);
  });

  test('Comprehensive Test: Products (صنف) creation, update, and search', () async {
    // 1. Create a category and type first
    final catId = await catDatasource.createCategory('موبايلات', null);
    final typeId = await catDatasource.createType(catId, 'سامسونج', null);

    // 2. Create a product (صنف جديد)
    final product = ProductEntity(
      id: 0,
      name: 'سامسونج جالاكسي S24',
      barcode: '6221234567890',
      categoryId: catId,
      productTypeId: typeId,
      description: 'هاتف ذكي 256 جيجا',
      unit: 'قطعة',
      currentQuantity: 15,
      minQuantity: 3,
      costPrice: 35000,
      sellPrice: 42000,
      groupPrice: 40000,
      groupQuantity: 5,
      weightedAvgCost: 35000,
      status: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final saveSuccess = await prodCubit.saveProduct(product);
    expect(saveSuccess, isTrue);

    // 3. Load products
    await prodCubit.loadProducts();
    expect(prodCubit.state, isA<ProductsLoaded>());
    var pLoaded = prodCubit.state as ProductsLoaded;
    expect(pLoaded.products.length, equals(1));
    final savedProduct = pLoaded.products.first;
    expect(savedProduct.name, equals('سامسونج جالاكسي S24'));
    expect(savedProduct.barcode, equals('6221234567890'));
    expect(savedProduct.categoryName, equals('موبايلات'));
    expect(savedProduct.productTypeName, equals('سامسونج'));
    expect(savedProduct.currentQuantity, equals(15));
    expect(savedProduct.sellPrice, equals(42000));

    // 4. Barcode lookup
    final barcodeResult = await prodCubit.searchByBarcode('6221234567890');
    expect(barcodeResult, isNotNull);
    expect(barcodeResult!.id, equals(savedProduct.id));

    // 5. Update Product
    final updatedProduct = savedProduct.copyWith(
      name: 'سامسونج جالاكسي S24 الترا',
      sellPrice: 45000,
    );
    final updateSuccess = await prodCubit.saveProduct(updatedProduct);
    expect(updateSuccess, isTrue);

    final fetched = await prodCubit.getById(savedProduct.id);
    expect(fetched, isNotNull);
    expect(fetched!.name, equals('سامسونج جالاكسي S24 الترا'));
    expect(fetched.sellPrice, equals(45000));

    // 6. Delete Product (soft delete)
    final deleteSuccess = await prodCubit.deleteProduct(savedProduct.id);
    expect(deleteSuccess, isTrue);

    await prodCubit.loadProducts();
    pLoaded = prodCubit.state as ProductsLoaded;
    expect(pLoaded.products.where((p) => p.id == savedProduct.id && p.status == 'active').length, equals(0));
  });

  test('Comprehensive Test: POS Sale, Stock Deduction, and Invoice Cancellation', () async {
    // 1. Create product with 20 units
    final prodId = await prodDatasource.create(ProductEntity(
      id: 0,
      name: 'سماعة بلوتوث لاسلكية',
      barcode: '9988776655',
      unit: 'قطعة',
      currentQuantity: 20,
      minQuantity: 2,
      costPrice: 200,
      sellPrice: 350,
      groupPrice: 300,
      groupQuantity: 3,
      weightedAvgCost: 200,
      status: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    final product = (await prodDatasource.getById(prodId))!;
    expect(product.currentQuantity, equals(20));

    // 2. Initialize POS, add 3 items to cart
    salesCubit.initPos();
    salesCubit.addToCart(product, quantity: 3);

    final posState = salesCubit.posState;
    expect(posState.cart.length, equals(1));
    expect(posState.totalAmount, equals(1050)); // 3 * 350

    // 3. Complete sale
    final saleId = await salesCubit.completeSale();
    expect(saleId, isNotNull);

    // 4. Verify product stock decreased from 20 to 17
    final productAfterSale = (await prodDatasource.getById(prodId))!;
    expect(productAfterSale.currentQuantity, equals(17));

    // 5. Verify sale invoice was saved
    final saleInvoice = await salesCubit.getSaleById(saleId!);
    expect(saleInvoice, isNotNull);
    expect(saleInvoice!.items.length, equals(1));
    expect(saleInvoice.totalAmount, equals(1050));
    expect(saleInvoice.status, equals('completed'));

    // 6. Cancel sale and verify stock is restored from 17 back to 20
    final cancelSuccess = await salesCubit.cancelSale(
      id: saleId,
      reason: 'طلب العميل إلغاء الفاتورة',
    );
    expect(cancelSuccess, isTrue);

    final productAfterCancel = (await prodDatasource.getById(prodId))!;
    expect(productAfterCancel.currentQuantity, equals(20));
  });

  test('Comprehensive Test: Customer Debt and Payment Collection', () async {
    // 1. Create customer
    final customer = CustomerEntity(
      id: 0,
      name: 'أحمد محمود',
      phone: '01012345678',
      totalBalance: 0,
      isActive: true,
      createdAt: DateTime.now(),
    );
    final saved = await custCubit.save(customer);
    expect(saved, isTrue);

    await custCubit.loadCustomers(search: 'أحمد');
    final custState = custCubit.state as CustomersLoaded;
    expect(custState.customers.length, equals(1));
    final cust = custState.customers.first;

    // 2. Add credit sale to customer
    final prodId = await prodDatasource.create(ProductEntity(
      id: 0,
      name: 'ماوس لاسلكي',
      unit: 'قطعة',
      currentQuantity: 10,
      minQuantity: 1,
      costPrice: 50,
      sellPrice: 100,
      groupPrice: 90,
      groupQuantity: 2,
      weightedAvgCost: 50,
      status: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    final product = (await prodDatasource.getById(prodId))!;

    salesCubit.initPos();
    salesCubit.selectCustomer(cust);
    salesCubit.addToCart(product, quantity: 2);
    salesCubit.setPaymentType('credit'); // على الحساب

    final saleId = await salesCubit.completeSale();
    expect(saleId, isNotNull);

    // 3. Verify customer debt increased by 200
    final custAfterSale = await custDatasource.getById(cust.id);
    expect(custAfterSale, isNotNull);
    expect(custAfterSale!.totalBalance, equals(200));

    // 4. Pay 150 from debt
    final paySuccess = await custCubit.addPayment(
      customerId: cust.id,
      amount: 150,
      notes: 'سداد جزئي',
    );
    expect(paySuccess, isTrue);

    // 5. Verify remaining debt is 50
    final custAfterPay = await custDatasource.getById(cust.id);
    expect(custAfterPay!.totalBalance, equals(50));
  });

  test('Comprehensive Test: Expense recording', () async {
    final expense = ExpenseEntity(
      id: 0,
      category: 'كهرباء ومياه',
      description: 'فاتورة كهرباء المحل',
      amount: 450,
      paymentMethod: 'cash',
      expenseDate: DateTime.now(),
      createdAt: DateTime.now(),
    );

    final success = await expCubit.createExpense(expense);
    expect(success, isTrue);

    await expCubit.loadExpenses();
    expect(expCubit.state, isA<ExpensesLoaded>());
    final expState = expCubit.state as ExpensesLoaded;
    expect(expState.expenses.length, equals(1));
    expect(expState.expenses.first.amount, equals(450));
  });

  test('Comprehensive Test: Inventory all-stock by piece counts, movement log, and product movement filtering', () async {
    // 1. Create product with initial quantity of 50 pieces
    final product = ProductEntity(
      id: 0,
      name: 'شاشة حماية زجاجية للمخزن',
      barcode: '6221199880011',
      unit: 'قطعة',
      currentQuantity: 50,
      minQuantity: 10,
      costPrice: 20,
      sellPrice: 40,
      groupPrice: 35,
      groupQuantity: 10,
      weightedAvgCost: 20,
      status: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final saveSuccess = await prodCubit.saveProduct(product);
    expect(saveSuccess, isTrue);

    await prodCubit.loadProducts();
    final createdProd = (prodCubit.state as ProductsLoaded).products.first;
    final prodId = createdProd.id;

    // 2. Load inventory data
    await invCubit.loadInventoryData();
    expect(invCubit.state, isA<InventoryLoaded>());
    var invState = invCubit.state as InventoryLoaded;

    // Verify all stock is present with accurate piece count
    expect(invState.allProducts.length, equals(1));
    expect(invState.allProducts.first.name, equals('شاشة حماية زجاجية للمخزن'));
    expect(invState.allProducts.first.currentQuantity, equals(50));
    expect(invState.allProducts.first.unit, equals('قطعة'));

    // 3. Record damage of 5 pieces
    final damageSuccess = await invCubit.recordDamage(
      productId: prodId,
      quantity: 5,
      reason: 'كسر أثناء النقل',
    );
    expect(damageSuccess, isTrue);

    invState = invCubit.state as InventoryLoaded;
    expect(invState.damages.length, equals(1));
    expect(invState.damages.first.quantity, equals(5));
    expect(invState.allProducts.first.currentQuantity, equals(45));

    // 4. Verify movement was logged and filterable
    expect(invState.movements.length, equals(1));
    expect(invState.movements.first.quantity, equals(-5));
    expect(invState.movements.first.quantityAfter, equals(45));

    await invCubit.filterMovementsByProduct(prodId, 'شاشة حماية زجاجية للمخزن');
    invState = invCubit.state as InventoryLoaded;
    expect(invState.filteredProductId, equals(prodId));
    expect(invState.filteredProductName, equals('شاشة حماية زجاجية للمخزن'));
    expect(invState.movements.length, equals(1));
  });
}

