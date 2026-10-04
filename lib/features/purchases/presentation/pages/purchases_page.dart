import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_routes.dart';
import '../cubit/purchases_cubit.dart';
import '../../domain/entities/purchase_entity.dart';

class PurchasesPage extends StatefulWidget {
  const PurchasesPage({super.key});

  @override
  State<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends State<PurchasesPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<PurchasesCubit>().loadPurchases();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سجل المشتريات وفواتير الوارد',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'إدارة فواتير المشتريات من الموردين وتحديث تكلفة المخزون',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.purchaseAdd),
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text('تسجيل فاتورة شراء جديدة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search Bar & Filter
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        context.read<PurchasesCubit>().loadPurchases(search: val);
                      },
                      decoration: InputDecoration(
                        hintText: 'البحث برقم فاتورة الشراء أو اسم المورد...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  context.read<PurchasesCubit>().loadPurchases();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      context.read<PurchasesCubit>().loadPurchases();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('تحديث'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Purchases Table
            Expanded(
              child: BlocBuilder<PurchasesCubit, PurchasesState>(
                builder: (context, state) {
                  if (state is PurchasesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is PurchasesError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                          const SizedBox(height: 12),
                          Text(state.message),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context.read<PurchasesCubit>().loadPurchases(),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is PurchasesLoaded) {
                    if (state.purchases.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            const Text(
                              'لا توجد فواتير مشتريات مسجلة',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text('يمكنك تسجيل فاتورة مشتريات جديدة باستخدام الزر أعلاه'),
                          ],
                        ),
                      );
                    }

                    final totalPurchases = state.purchases
                        .where((p) => p.status == 'completed')
                        .fold<double>(0, (sum, p) => sum + p.totalAmount);
                    final totalPaid = state.purchases
                        .where((p) => p.status == 'completed')
                        .fold<double>(0, (sum, p) => sum + p.paidAmount);

                    return Column(
                      children: [
                        // Quick Stats Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'إجمالي فواتير الشراء: ${state.purchases.length}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 32),
                              Text(
                                'إجمالي قيمة المشتريات: ${totalPurchases.toStringAsFixed(2)} ج',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                              ),
                              const Spacer(),
                              Text(
                                'إجمالي المدفوع نقداً: ${totalPaid.toStringAsFixed(2)} ج',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success),
                              ),
                            ],
                          ),
                        ),

                        // Table
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(AppTheme.background),
                                    columns: const [
                                      DataColumn(label: Text('رقم الفاتورة', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('التاريخ والوقت', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('المورد', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('طريقة السداد', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('المدفوع', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('المتبقي للمورد', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: state.purchases.map((purchase) {
                                      final isCancelled = purchase.status == 'cancelled';
                                      final isCash = purchase.paymentType == 'cash';

                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            InkWell(
                                              onTap: () => context.go('${AppRoutes.purchases}/${purchase.id}'),
                                              child: Text(
                                                purchase.invoiceNumber,
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(dateFormat.format(purchase.createdAt))),
                                          DataCell(Text(purchase.supplierName ?? 'مورد عام')),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isCash ? AppTheme.success.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                isCash ? 'نقدي' : 'آجل',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isCash ? AppTheme.success : Colors.orange.shade900,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              '${purchase.totalAmount.toStringAsFixed(2)} ج',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                decoration: isCancelled ? TextDecoration.lineThrough : null,
                                              ),
                                            ),
                                          ),
                                          DataCell(Text('${purchase.paidAmount.toStringAsFixed(2)} ج')),
                                          DataCell(
                                            Text(
                                              '${purchase.remainingAmount.toStringAsFixed(2)} ج',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: purchase.remainingAmount > 0 ? Colors.orange.shade900 : AppTheme.textSecondary,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isCancelled
                                                    ? AppTheme.error.withValues(alpha: 0.12)
                                                    : AppTheme.success.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                isCancelled ? 'ملغية' : 'مكتملة',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isCancelled ? AppTheme.error : AppTheme.success,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove_red_eye_outlined, size: 20),
                                                  tooltip: 'عرض الفاتورة',
                                                  onPressed: () => context.go('${AppRoutes.purchases}/${purchase.id}'),
                                                ),
                                                if (!isCancelled)
                                                  IconButton(
                                                    icon: const Icon(Icons.cancel_outlined, size: 20, color: AppTheme.error),
                                                    tooltip: 'إلغاء الفاتورة وإعادة البضاعة للمورد',
                                                    onPressed: () => _confirmCancelPurchase(context, purchase),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancelPurchase(BuildContext context, PurchaseEntity purchase) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إلغاء فاتورة الشراء #${purchase.invoiceNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تنبيه: سيؤدي إلغاء الفاتورة إلى خصم الكميات من المخزن واسترداد المبالغ النقدية وتعديل رصيد المورد.',
              style: TextStyle(color: AppTheme.error, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'سبب الإلغاء *',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('رجوع')),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final success = await context.read<PurchasesCubit>().cancelPurchase(
                    id: purchase.id,
                    reason: reasonController.text.trim(),
                  );
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إلغاء فاتورة الشراء بنجاح')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );
  }
}
