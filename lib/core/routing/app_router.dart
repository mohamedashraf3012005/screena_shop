import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/products/presentation/pages/products_page.dart';
import '../../features/products/presentation/pages/product_form_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/customers/presentation/pages/customers_page.dart';
import '../../features/customers/presentation/pages/customer_form_page.dart';
import '../../features/customers/presentation/pages/customer_detail_page.dart';
import '../../features/suppliers/presentation/pages/suppliers_page.dart';
import '../../features/suppliers/presentation/pages/supplier_form_page.dart';
import '../../features/suppliers/presentation/pages/supplier_detail_page.dart';
import '../../features/sales/presentation/pages/sales_page.dart';
import '../../features/sales/presentation/pages/pos_page.dart';
import '../../features/sales/presentation/pages/sale_detail_page.dart';
import '../../features/purchases/presentation/pages/purchases_page.dart';
import '../../features/purchases/presentation/pages/purchase_form_page.dart';
import '../../features/purchases/presentation/pages/purchase_detail_page.dart';
import '../../features/inventory/presentation/pages/inventory_page.dart';
import '../../features/inventory/presentation/pages/stock_adjustment_page.dart';
import '../../features/inventory/presentation/pages/stock_damage_page.dart';
import '../../features/treasury/presentation/pages/treasury_page.dart';
import '../../features/expenses/presentation/pages/expenses_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/users/presentation/pages/users_page.dart';
import '../widgets/main_layout.dart';
import 'app_routes.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => GoRouter(
        navigatorKey: _rootNavigatorKey,
        initialLocation: AppRoutes.login,
        routes: [
          GoRoute(
            path: AppRoutes.login,
            builder: (_, __) => const LoginPage(),
          ),
          ShellRoute(
            navigatorKey: _shellNavigatorKey,
            builder: (context, state, child) => MainLayout(child: child),
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (_, __) => const DashboardPage(),
              ),
              GoRoute(
                path: AppRoutes.products,
                builder: (_, __) => const ProductsPage(),
              ),
              GoRoute(
                path: AppRoutes.productAdd,
                builder: (_, __) => const ProductFormPage(),
              ),
              GoRoute(
                path: AppRoutes.productEdit,
                builder: (context, state) => ProductFormPage(
                  productId: int.tryParse(state.pathParameters['id'] ?? ''),
                ),
              ),
              GoRoute(
                path: AppRoutes.categories,
                builder: (_, __) => const CategoriesPage(),
              ),
              GoRoute(
                path: AppRoutes.customers,
                builder: (_, __) => const CustomersPage(),
              ),
              GoRoute(
                path: AppRoutes.customerAdd,
                builder: (_, __) => const CustomerFormPage(),
              ),
              GoRoute(
                path: AppRoutes.customerEdit,
                builder: (context, state) => CustomerFormPage(
                  customerId:
                      int.tryParse(state.pathParameters['id'] ?? ''),
                ),
              ),
              GoRoute(
                path: AppRoutes.customerDetail,
                builder: (context, state) => CustomerDetailPage(
                  customerId:
                      int.parse(state.pathParameters['id'] ?? '0'),
                ),
              ),
              GoRoute(
                path: AppRoutes.suppliers,
                builder: (_, __) => const SuppliersPage(),
              ),
              GoRoute(
                path: AppRoutes.supplierAdd,
                builder: (_, __) => const SupplierFormPage(),
              ),
              GoRoute(
                path: AppRoutes.supplierEdit,
                builder: (context, state) => SupplierFormPage(
                  supplierId:
                      int.tryParse(state.pathParameters['id'] ?? ''),
                ),
              ),
              GoRoute(
                path: AppRoutes.supplierDetail,
                builder: (context, state) => SupplierDetailPage(
                  supplierId:
                      int.parse(state.pathParameters['id'] ?? '0'),
                ),
              ),
              GoRoute(
                path: AppRoutes.sales,
                builder: (_, __) => const SalesPage(),
              ),
              GoRoute(
                path: AppRoutes.pos,
                builder: (_, __) => const PosPage(),
              ),
              GoRoute(
                path: AppRoutes.saleDetail,
                builder: (context, state) => SaleDetailPage(
                  saleId: int.parse(state.pathParameters['id'] ?? '0'),
                ),
              ),
              GoRoute(
                path: AppRoutes.purchases,
                builder: (_, __) => const PurchasesPage(),
              ),
              GoRoute(
                path: AppRoutes.purchaseAdd,
                builder: (_, __) => const PurchaseFormPage(),
              ),
              GoRoute(
                path: AppRoutes.purchaseDetail,
                builder: (context, state) => PurchaseDetailPage(
                  purchaseId:
                      int.parse(state.pathParameters['id'] ?? '0'),
                ),
              ),
              GoRoute(
                path: AppRoutes.inventory,
                builder: (_, __) => const InventoryPage(),
              ),
              GoRoute(
                path: AppRoutes.stockAdjustment,
                builder: (_, __) => const StockAdjustmentPage(),
              ),
              GoRoute(
                path: AppRoutes.stockDamage,
                builder: (_, __) => const StockDamagePage(),
              ),
              GoRoute(
                path: AppRoutes.treasury,
                builder: (_, __) => const TreasuryPage(),
              ),
              GoRoute(
                path: AppRoutes.expenses,
                builder: (_, __) => const ExpensesPage(),
              ),
              GoRoute(
                path: AppRoutes.reports,
                builder: (_, __) => const ReportsPage(),
              ),
              GoRoute(
                path: AppRoutes.settings,
                builder: (_, __) => const SettingsPage(),
              ),
              GoRoute(
                path: AppRoutes.users,
                builder: (_, __) => const UsersPage(),
              ),
            ],
          ),
        ],
      );
}
