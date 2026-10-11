import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../routing/app_routes.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../features/products/presentation/cubit/products_cubit.dart';
import '../../features/sales/presentation/cubit/sales_cubit.dart';
import '../../features/purchases/presentation/cubit/purchases_cubit.dart';
import '../../features/inventory/presentation/cubit/inventory_cubit.dart';
import '../../features/treasury/presentation/cubit/treasury_cubit.dart';
import '../../features/expenses/presentation/cubit/expenses_cubit.dart';
import '../../features/customers/presentation/cubit/customers_cubit.dart';
import '../../features/suppliers/presentation/cubit/suppliers_cubit.dart';
import '../../features/categories/presentation/cubit/categories_cubit.dart';
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart';

Future<void> showFactoryResetDialog(BuildContext context) async {
  final passwordController = TextEditingController();
  bool obscurePassword = true;
  String? errorMessage;
  bool isResetting = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (context, setDlgState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.error, width: 2),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'ترجيع الكل كما كان (تفريغ النظام بالكامل)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.error,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ تحذير شديد الأهمية - لا يمكن التراجع بعد هذه الخطوة:',
                        style: TextStyle(
                          color: AppTheme.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'عند تأكيد هذا الإجراء، سيتم تفريغ كافة بيانات النظام بالكامل والبدء من الصفر تماماً:\n'
                        '• مسح وحذف جميع المنتجات والمخزون وحركاته بالكامل (0 قطعة).\n'
                        '• مسح جميع فواتير المبيعات والمشتريات والمرتجعات.\n'
                        '• تصفير الخزينة والمصروفات بالكامل (0 جنيه).\n'
                        '• مسح جميع العملاء والموردين وتصفير المديونيات.\n'
                        '• النظام سيعود فارغاً تماماً كما لو قمت بتثبيته لأول مرة الآن.',
                        style: TextStyle(fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'لتأكيد هذه العملية، يرجى كتابة كلمة مرور المدير:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور التأكيدية',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setDlgState(() => obscurePassword = !obscurePassword),
                    ),
                    errorText: errorMessage,
                  ),
                  onSubmitted: (_) {},
                ),
                if (isResetting) ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: AppTheme.error),
                        SizedBox(height: 8),
                        Text('جارٍ تفريغ وتصفير النظام بالكامل...'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isResetting ? null : () => Navigator.pop(dialogCtx),
              child: const Text('إلغاء الأمر'),
            ),
            ElevatedButton.icon(
              onPressed: isResetting
                  ? null
                  : () async {
                      final enteredPassword = passwordController.text.trim();
                      if (enteredPassword.isEmpty) {
                        setDlgState(() => errorMessage = 'يرجى إدخال كلمة المرور');
                        return;
                      }

                      setDlgState(() {
                        errorMessage = null;
                        isResetting = true;
                      });

                      final success = await context.read<SettingsCubit>().factoryReset(enteredPassword);

                      if (context.mounted) {
                        if (success) {
                          // Refresh all active cubits to zero state
                          try {
                            context.read<ProductsCubit>().loadProducts();
                            context.read<SalesCubit>().loadSales();
                            context.read<PurchasesCubit>().loadPurchases();
                            context.read<InventoryCubit>().loadInventoryData();
                            context.read<TreasuryCubit>().loadTreasury();
                            context.read<ExpensesCubit>().loadExpenses();
                            context.read<CustomersCubit>().loadCustomers();
                            context.read<SuppliersCubit>().loadSuppliers();
                            context.read<CategoriesCubit>().loadCategories();
                            context.read<DashboardCubit>().loadDashboard();
                          } catch (_) {}

                          Navigator.pop(dialogCtx);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم تفريغ النظام بنجاح! تم ترجيع الكل كما كان والبدء من الصفر تماماً.'),
                              backgroundColor: AppTheme.success,
                              duration: Duration(seconds: 4),
                            ),
                          );

                          // Navigate to dashboard
                          context.go(AppRoutes.dashboard);
                        } else {
                          setDlgState(() {
                            isResetting = false;
                            errorMessage = 'كلمة المرور غير صحيحة! لم يتم تفريغ النظام.';
                          });
                        }
                      }
                    },
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text('تأكيد ترجيع الكل كما كان'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ],
        );
      },
    ),
  );
}
