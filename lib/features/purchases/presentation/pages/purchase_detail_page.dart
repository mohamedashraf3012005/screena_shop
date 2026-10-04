import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_routes.dart';
import '../cubit/purchases_cubit.dart';
import '../../domain/entities/purchase_entity.dart';

class PurchaseDetailPage extends StatefulWidget {
  final int purchaseId;

  const PurchaseDetailPage({super.key, required this.purchaseId});

  @override
  State<PurchaseDetailPage> createState() => _PurchaseDetailPageState();
}

class _PurchaseDetailPageState extends State<PurchaseDetailPage> {
  PurchaseEntity? _purchase;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPurchase();
  }

  Future<void> _loadPurchase() async {
    setState(() => _isLoading = true);
    final purchase = await context.read<PurchasesCubit>().getPurchaseById(widget.purchaseId);
    if (mounted) {
      setState(() {
        _purchase = purchase;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_purchase == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('تفاصيل فاتورة الشراء')),
        body: const Center(child: Text('الفاتورة غير موجودة')),
      );
    }

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final isCancelled = _purchase!.status == 'cancelled';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('فاتورة مشتريات #${_purchase!.invoiceNumber}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.purchases),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPurchase,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.border),
              ),
              color: AppTheme.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'فاتورة شراء وارد',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'رقم الفاتورة: #${_purchase!.invoiceNumber}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text('التاريخ: ${dateFormat.format(_purchase!.createdAt)}'),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isCancelled
                                    ? AppTheme.error.withValues(alpha: 0.12)
                                    : AppTheme.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isCancelled ? 'فاتورة ملغية' : 'مكتملة ومستلمة',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isCancelled ? AppTheme.error : AppTheme.success,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('المورد: ${_purchase!.supplierName ?? "مورد نقدي عام"}'),
                            Text('طريقة السداد: ${_purchase!.paymentType == "cash" ? "نقدي" : "آجل"}'),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 40),

                    // Items Table
                    const Text('الأصناف الواردة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Table(
                      border: TableBorder.all(color: AppTheme.border, borderRadius: BorderRadius.circular(8)),
                      columnWidths: const {
                        0: FlexColumnWidth(4),
                        1: FlexColumnWidth(1.5),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(2),
                      },
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(color: AppTheme.background),
                          children: const [
                            Padding(padding: EdgeInsets.all(10), child: Text('الصنف', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(10), child: Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(10), child: Text('سعر الشراء', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(10), child: Text('إجمالي التكلفة', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                        ..._purchase!.items.map((item) {
                          return TableRow(
                            children: [
                              Padding(padding: const EdgeInsets.all(10), child: Text(item.productName)),
                              Padding(padding: const EdgeInsets.all(10), child: Text('${item.quantity}')),
                              Padding(padding: const EdgeInsets.all(10), child: Text('${item.unitCost.toStringAsFixed(2)} ج')),
                              Padding(padding: const EdgeInsets.all(10), child: Text('${item.totalCost.toStringAsFixed(2)} ج')),
                            ],
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Financial Summary Breakdown
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 300,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('المجموع الفرعي:'),
                                Text('${_purchase!.subtotal.toStringAsFixed(2)} ج'),
                              ],
                            ),
                            if (_purchase!.discountAmount > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('الخصم:'),
                                  Text('- ${_purchase!.discountAmount.toStringAsFixed(2)} ج', style: const TextStyle(color: AppTheme.error)),
                                ],
                              ),
                            ],
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('إجمالي الفاتورة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(
                                  '${_purchase!.totalAmount.toStringAsFixed(2)} ج',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('المدفوع نقداً:'),
                                Text('${_purchase!.paidAmount.toStringAsFixed(2)} ج', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            if (_purchase!.remainingAmount > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('المتبقي للمورد:'),
                                  Text(
                                    '${_purchase!.remainingAmount.toStringAsFixed(2)} ج',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    if (isCancelled && _purchase!.cancelReason != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          'سبب الإلغاء: ${_purchase!.cancelReason}',
                          style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],

                    const SizedBox(height: 36),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => context.go(AppRoutes.purchases),
                          child: const Text('رجوع لسجل المشتريات'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
