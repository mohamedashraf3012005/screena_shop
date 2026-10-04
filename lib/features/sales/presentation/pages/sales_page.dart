import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_routes.dart';
import '../cubit/sales_cubit.dart';
import '../../domain/entities/sale_entity.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SalesCubit>().loadSales();
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
                      'سجل فواتير المبيعات',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'عرض وأرشفة فواتير المبيعات، حساب الأرباح، وإلغاء الفواتير',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.pos),
                  icon: const Icon(Icons.point_of_sale_rounded),
                  label: const Text('شاشة الكاشير (POS)'),
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
                        context.read<SalesCubit>().loadSales(search: val);
                      },
                      decoration: InputDecoration(
                        hintText: 'البحث برقم الفاتورة أو اسم العميل...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  context.read<SalesCubit>().loadSales();
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
                      context.read<SalesCubit>().loadSales();
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

            // Sales Table
            Expanded(
              child: BlocBuilder<SalesCubit, SalesState>(
                builder: (context, state) {
                  if (state is SalesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is SalesError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                          const SizedBox(height: 12),
                          Text(state.message),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context.read<SalesCubit>().loadSales(),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is SalesLoaded) {
                    if (state.sales.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            const Text(
                              'لا توجد فواتير مبيعات مسجلة',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text('انتقل إلى شاشة الكاشير لإنشاء فاتورة جديدة'),
                          ],
                        ),
                      );
                    }

                    final totalSalesAmount = state.sales
                        .where((s) => s.status == 'completed')
                        .fold<double>(0, (sum, s) => sum + s.totalAmount);
                    final totalProfitAmount = state.sales
                        .where((s) => s.status == 'completed')
                        .fold<double>(0, (sum, s) => sum + s.profitAmount);

                    return Column(
                      children: [
                        // Quick Stats Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'إجمالي الفواتير: ${state.sales.length}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 32),
                              Text(
                                'إجمالي المبيعات: ${totalSalesAmount.toStringAsFixed(2)} ج',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                              ),
                              const Spacer(),
                              Text(
                                'إجمالي صافي الربح: ${totalProfitAmount.toStringAsFixed(2)} ج',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success),
                              ),
                            ],
                          ),
                        ),

                        // Invoices Table
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
                                      DataColumn(label: Text('العميل', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('طريقة الدفع', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('المدفوع', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('الربح', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: state.sales.map((sale) {
                                      final isCancelled = sale.status == 'cancelled';
                                      final isCash = sale.paymentType == 'cash';

                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            InkWell(
                                              onTap: () => context.go('${AppRoutes.sales}/${sale.id}'),
                                              child: Text(
                                                sale.invoiceNumber,
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(dateFormat.format(sale.createdAt))),
                                          DataCell(Text(sale.customerName ?? 'نقدي / عام')),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isCash ? AppTheme.success.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                isCash ? 'نقدي' : 'آجل (شكك)',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isCash ? AppTheme.success : Colors.orange.shade900,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              '${sale.totalAmount.toStringAsFixed(2)} ج',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                decoration: isCancelled ? TextDecoration.lineThrough : null,
                                              ),
                                            ),
                                          ),
                                          DataCell(Text('${sale.paidAmount.toStringAsFixed(2)} ج')),
                                          DataCell(
                                            Text(
                                              '${sale.profitAmount.toStringAsFixed(2)} ج',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isCancelled ? AppTheme.textSecondary : AppTheme.success,
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
                                                  onPressed: () => context.go('${AppRoutes.sales}/${sale.id}'),
                                                ),
                                                if (!isCancelled)
                                                  IconButton(
                                                    icon: const Icon(Icons.cancel_outlined, size: 20, color: AppTheme.error),
                                                    tooltip: 'إلغاء الفاتورة واسترجاع البضاعة',
                                                    onPressed: () => _confirmCancelSale(context, sale),
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

  void _confirmCancelSale(BuildContext context, SaleEntity sale) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إلغاء الفاتورة #${sale.invoiceNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تنبيه: سيؤدي إلغاء الفاتورة إلى إعادة الأصناف إلى المخزن واسترداد المبالغ النقدية وتعديل رصيد العميل إن وجد.',
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
              final success = await context.read<SalesCubit>().cancelSale(
                    id: sale.id,
                    reason: reasonController.text.trim(),
                  );
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إلغاء الفاتورة واستعادة البضاعة للمخزن')),
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
