import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_routes.dart';
import '../cubit/sales_cubit.dart';
import '../../domain/entities/sale_entity.dart';
import '../../../../core/utils/pdf_invoice_helper.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/domain/entities/settings_entity.dart';

class SaleDetailPage extends StatefulWidget {
  final int saleId;

  const SaleDetailPage({super.key, required this.saleId});

  @override
  State<SaleDetailPage> createState() => _SaleDetailPageState();
}

class _SaleDetailPageState extends State<SaleDetailPage> {
  SaleEntity? _sale;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSale();
  }

  Future<void> _loadSale() async {
    setState(() => _isLoading = true);
    final sale = await context.read<SalesCubit>().getSaleById(widget.saleId);
    if (mounted) {
      setState(() {
        _sale = sale;
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

    if (_sale == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('تفاصيل الفاتورة')),
        body: const Center(child: Text('الفاتورة غير موجودة')),
      );
    }

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final isCancelled = _sale!.status == 'cancelled';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('فاتورة مبيعات #${_sale!.invoiceNumber}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.sales),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSale,
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
                    // Invoice Top Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'فاتورة مبيعات',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'رقم الفاتورة: #${_sale!.invoiceNumber}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text('التاريخ: ${dateFormat.format(_sale!.createdAt)}'),
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
                                isCancelled ? 'فاتورة ملغية' : 'مكتملة ومدفوعة',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isCancelled ? AppTheme.error : AppTheme.success,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('العميل: ${_sale!.customerName ?? "عميل نقدي / عام"}'),
                            Text('طريقة السداد: ${_sale!.paymentType == "cash" ? "نقدي (كاش)" : "آجل (شكك)"}'),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 40),

                    // Items Table
                    const Text('بنود الفاتورة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                            Padding(padding: EdgeInsets.all(10), child: Text('سعر الوحدة', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(10), child: Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                        ..._sale!.items.map((item) {
                          return TableRow(
                            children: [
                              Padding(padding: const EdgeInsets.all(10), child: Text(item.productName)),
                              Padding(padding: const EdgeInsets.all(10), child: Text('${item.quantity}')),
                              Padding(padding: const EdgeInsets.all(10), child: Text('${item.unitPrice.toStringAsFixed(2)} ج')),
                              Padding(padding: const EdgeInsets.all(10), child: Text('${item.totalPrice.toStringAsFixed(2)} ج')),
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
                                Text('${_sale!.subtotal.toStringAsFixed(2)} ج'),
                              ],
                            ),
                            if (_sale!.discountAmount > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('الخصم:'),
                                  Text('- ${_sale!.discountAmount.toStringAsFixed(2)} ج', style: const TextStyle(color: AppTheme.error)),
                                ],
                              ),
                            ],
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('الإجمالي المستحق:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(
                                  '${_sale!.totalAmount.toStringAsFixed(2)} ج',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('المبلغ المدفوع:'),
                                Text('${_sale!.paidAmount.toStringAsFixed(2)} ج', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            if (_sale!.remainingAmount > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('المتبقي على الحساب:'),
                                  Text(
                                    '${_sale!.remainingAmount.toStringAsFixed(2)} ج',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('صافي ربح الفاتورة:'),
                                Text(
                                  '${_sale!.profitAmount.toStringAsFixed(2)} ج',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (isCancelled && _sale!.cancelReason != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          'سبب الإلغاء: ${_sale!.cancelReason}',
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
                          onPressed: () => context.go(AppRoutes.sales),
                          child: const Text('رجوع لسجل المبيعات'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final settingsState = context.read<SettingsCubit>().state;
                              final settings = settingsState is SettingsLoaded
                                  ? settingsState.settings
                                  : ShopSettingsEntity.defaultSettings;
                              await PdfInvoiceHelper.printReceipt(
                                sale: _sale!,
                                settings: settings,
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('حدث خطأ أثناء الطباعة: $e'),
                                    backgroundColor: AppTheme.error,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.print_rounded),
                          label: const Text('طباعة إيصال الفاتورة (80mm)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
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
