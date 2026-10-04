import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/di/injection_container.dart' as di;

import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/products/presentation/cubit/products_cubit.dart';
import 'features/categories/presentation/cubit/categories_cubit.dart';
import 'features/customers/presentation/cubit/customers_cubit.dart';
import 'features/suppliers/presentation/cubit/suppliers_cubit.dart';
import 'features/sales/presentation/cubit/sales_cubit.dart';
import 'features/purchases/presentation/cubit/purchases_cubit.dart';
import 'features/inventory/presentation/cubit/inventory_cubit.dart';
import 'features/treasury/presentation/cubit/treasury_cubit.dart';
import 'features/expenses/presentation/cubit/expenses_cubit.dart';
import 'features/reports/presentation/cubit/reports_cubit.dart';
import 'features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.setupDependencies();
  runApp(const ScreenaShopApp());
}

class ScreenaShopApp extends StatelessWidget {
  const ScreenaShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => di.sl<AuthCubit>()),
        BlocProvider<ProductsCubit>(create: (_) => di.sl<ProductsCubit>()),
        BlocProvider<CategoriesCubit>(create: (_) => di.sl<CategoriesCubit>()),
        BlocProvider<CustomersCubit>(create: (_) => di.sl<CustomersCubit>()),
        BlocProvider<SuppliersCubit>(create: (_) => di.sl<SuppliersCubit>()),
        BlocProvider<SalesCubit>(create: (_) => di.sl<SalesCubit>()),
        BlocProvider<PurchasesCubit>(create: (_) => di.sl<PurchasesCubit>()),
        BlocProvider<InventoryCubit>(create: (_) => di.sl<InventoryCubit>()),
        BlocProvider<TreasuryCubit>(create: (_) => di.sl<TreasuryCubit>()),
        BlocProvider<ExpensesCubit>(create: (_) => di.sl<ExpensesCubit>()),
        BlocProvider<ReportsCubit>(create: (_) => di.sl<ReportsCubit>()),
        BlocProvider<DashboardCubit>(create: (_) => di.sl<DashboardCubit>()),
        BlocProvider<SettingsCubit>(
          create: (_) => di.sl<SettingsCubit>()..loadSettings(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Screena Shop - نظام إدارة المخازن والمبيعات',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        locale: const Locale('ar', 'EG'),
        supportedLocales: const [
          Locale('ar', 'EG'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox(),
          );
        },
      ),
    );
  }
}
