import 'package:get_it/get_it.dart';
import '../database/app_database.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/products/data/datasources/products_local_datasource.dart';
import '../../features/products/data/repositories/products_repository_impl.dart';
import '../../features/products/domain/repositories/products_repository.dart';
import '../../features/products/presentation/cubit/products_cubit.dart';
import '../../features/categories/data/datasources/categories_local_datasource.dart';
import '../../features/categories/data/repositories/categories_repository_impl.dart';
import '../../features/categories/domain/repositories/categories_repository.dart';
import '../../features/categories/presentation/cubit/categories_cubit.dart';
import '../../features/customers/data/datasources/customers_local_datasource.dart';
import '../../features/customers/data/repositories/customers_repository_impl.dart';
import '../../features/customers/domain/repositories/customers_repository.dart';
import '../../features/customers/presentation/cubit/customers_cubit.dart';
import '../../features/suppliers/data/datasources/suppliers_local_datasource.dart';
import '../../features/suppliers/data/repositories/suppliers_repository_impl.dart';
import '../../features/suppliers/domain/repositories/suppliers_repository.dart';
import '../../features/suppliers/presentation/cubit/suppliers_cubit.dart';
import '../../features/sales/data/datasources/sales_local_datasource.dart';
import '../../features/sales/data/repositories/sales_repository_impl.dart';
import '../../features/sales/domain/repositories/sales_repository.dart';
import '../../features/sales/presentation/cubit/sales_cubit.dart';
import '../../features/purchases/data/datasources/purchases_local_datasource.dart';
import '../../features/purchases/data/repositories/purchases_repository_impl.dart';
import '../../features/purchases/domain/repositories/purchases_repository.dart';
import '../../features/purchases/presentation/cubit/purchases_cubit.dart';
import '../../features/inventory/data/datasources/inventory_local_datasource.dart';
import '../../features/inventory/data/repositories/inventory_repository_impl.dart';
import '../../features/inventory/domain/repositories/inventory_repository.dart';
import '../../features/inventory/presentation/cubit/inventory_cubit.dart';
import '../../features/treasury/data/datasources/treasury_local_datasource.dart';
import '../../features/treasury/data/repositories/treasury_repository_impl.dart';
import '../../features/treasury/domain/repositories/treasury_repository.dart';
import '../../features/treasury/presentation/cubit/treasury_cubit.dart';
import '../../features/expenses/data/datasources/expenses_local_datasource.dart';
import '../../features/expenses/data/repositories/expenses_repository_impl.dart';
import '../../features/expenses/domain/repositories/expenses_repository.dart';
import '../../features/expenses/presentation/cubit/expenses_cubit.dart';
import '../../features/reports/data/datasources/reports_local_datasource.dart';
import '../../features/reports/data/repositories/reports_repository_impl.dart';
import '../../features/reports/domain/repositories/reports_repository.dart';
import '../../features/reports/presentation/cubit/reports_cubit.dart';
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../features/settings/data/datasources/settings_local_datasource.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';

final sl = GetIt.instance;

Future<void> setupDependencies() async {
  // ─── Database ───
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // ─── Auth ───
  sl.registerLazySingleton<AuthLocalDatasource>(
      () => AuthLocalDatasource(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton(() => LoginUsecase(sl()));
  sl.registerFactory(() => AuthCubit(sl()));

  // ─── Categories ───
  sl.registerLazySingleton<CategoriesLocalDatasource>(
      () => CategoriesLocalDatasource(sl()));
  sl.registerLazySingleton<CategoriesRepository>(
      () => CategoriesRepositoryImpl(sl()));
  sl.registerFactory(() => CategoriesCubit(sl()));

  // ─── Products ───
  sl.registerLazySingleton<ProductsLocalDatasource>(
      () => ProductsLocalDatasource(sl()));
  sl.registerLazySingleton<ProductsRepository>(
      () => ProductsRepositoryImpl(sl()));
  sl.registerFactory(() => ProductsCubit(sl()));

  // ─── Inventory ───
  sl.registerLazySingleton<InventoryLocalDatasource>(
      () => InventoryLocalDatasource(sl()));
  sl.registerLazySingleton<InventoryRepository>(
      () => InventoryRepositoryImpl(sl()));
  sl.registerFactory(() => InventoryCubit(sl<InventoryRepository>(), sl<ProductsRepository>()));

  // ─── Customers ───
  sl.registerLazySingleton<CustomersLocalDatasource>(
      () => CustomersLocalDatasource(sl()));
  sl.registerLazySingleton<CustomersRepository>(
      () => CustomersRepositoryImpl(sl()));
  sl.registerFactory(() => CustomersCubit(sl()));

  // ─── Suppliers ───
  sl.registerLazySingleton<SuppliersLocalDatasource>(
      () => SuppliersLocalDatasource(sl()));
  sl.registerLazySingleton<SuppliersRepository>(
      () => SuppliersRepositoryImpl(sl()));
  sl.registerFactory(() => SuppliersCubit(sl()));

  // ─── Sales ───
  sl.registerLazySingleton<SalesLocalDatasource>(
      () => SalesLocalDatasource(sl()));
  sl.registerLazySingleton<SalesRepository>(() => SalesRepositoryImpl(sl()));
  sl.registerFactory(() => SalesCubit(sl(), sl()));

  // ─── Purchases ───
  sl.registerLazySingleton<PurchasesLocalDatasource>(
      () => PurchasesLocalDatasource(sl()));
  sl.registerLazySingleton<PurchasesRepository>(
      () => PurchasesRepositoryImpl(sl()));
  sl.registerFactory(() => PurchasesCubit(sl()));

  // ─── Treasury ───
  sl.registerLazySingleton<TreasuryLocalDatasource>(
      () => TreasuryLocalDatasource(sl()));
  sl.registerLazySingleton<TreasuryRepository>(
      () => TreasuryRepositoryImpl(sl()));
  sl.registerFactory(() => TreasuryCubit(sl()));

  // ─── Expenses ───
  sl.registerLazySingleton<ExpensesLocalDatasource>(
      () => ExpensesLocalDatasource(sl()));
  sl.registerLazySingleton<ExpensesRepository>(
      () => ExpensesRepositoryImpl(sl()));
  sl.registerFactory(() => ExpensesCubit(sl()));

  // ─── Reports ───
  sl.registerLazySingleton<ReportsLocalDatasource>(
      () => ReportsLocalDatasource(sl()));
  sl.registerLazySingleton<ReportsRepository>(
      () => ReportsRepositoryImpl(sl()));
  sl.registerFactory(() => ReportsCubit(sl()));

  // ─── Dashboard ───
  sl.registerFactory(() => DashboardCubit(sl()));

  // ─── Settings ───
  sl.registerLazySingleton<SettingsLocalDatasource>(
      () => SettingsLocalDatasource(sl()));
  sl.registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(sl()));
  sl.registerFactory(() => SettingsCubit(sl()));
}
