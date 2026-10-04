import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_routes.dart';
import '../cubit/suppliers_cubit.dart';
import '../../domain/entities/supplier_entity.dart';

class SupplierDetailPage extends StatefulWidget {
  final int supplierId;

  const SupplierDetailPage({super.key, required this.supplierId});

  @override
  State<SupplierDetailPage> createState() => _SupplierDetailPageState();
}

class _SupplierDetailPageState extends State<SupplierDetailPage> {
  SupplierEntity? _supplier;
  List<SupplierTransactionEntity> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final cubit = context.read<SuppliersCubit>();
    final supplier = await cubit.getById(widget.supplierId);
    final transactions = await cubit.getTransactions(widget.supplierId);

    if (mounted) {
      setState(() {
        _supplier = supplier;
        _transactions = transactions;
        _isLoading = false;
      });
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح واتساب لهذا الرقم')),
        );
      }
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

    if (_supplier == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('كشف حساب المورد')),
        body: const Center(child: Text('المورد غير موجود')),
      );
    }

    final hasDebt = _supplier!.totalBalance > 0;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('كشف حساب المورد: ${_supplier!.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.suppliers),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'تعديل البيانات',
            onPressed: () => context.go('/suppliers/${_supplier!.id}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث البيانات',
            onPressed: _loadData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Supplier Profile Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.border),
              ),
              color: AppTheme.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.amber.withValues(alpha: 0.15),
                      foregroundColor: Colors.amber.shade900,
                      child: const Icon(Icons.business, size: 40),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _supplier!.name,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              if (_supplier!.company != null && _supplier!.company!.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _supplier!.company!,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _supplier!.isActive ? AppTheme.success.withValues(alpha: 0.12) : AppTheme.border,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _supplier!.isActive ? 'نشط' : 'معطل',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _supplier!.isActive ? AppTheme.success : AppTheme.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 24,
                            runSpacing: 8,
                            children: [
                              if (_supplier!.phone != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.phone, size: 16, color: AppTheme.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(_supplier!.phone!, style: const TextStyle(color: AppTheme.textSecondary)),
                                  ],
                                ),
                              if (_supplier!.whatsapp != null)
                                InkWell(
                                  onTap: () => _launchWhatsApp(_supplier!.whatsapp!),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.chat, size: 16, color: Colors.green),
                                      const SizedBox(width: 6),
                                      Text(
                                        _supplier!.whatsapp!,
                                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.open_in_new, size: 12, color: Colors.green),
                                    ],
                                  ),
                                ),
                              if (_supplier!.address != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on, size: 16, color: AppTheme.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(_supplier!.address!, style: const TextStyle(color: AppTheme.textSecondary)),
                                  ],
                                ),
                            ],
                          ),
                          if (_supplier!.notes != null && _supplier!.notes!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              'ملاحظات: ${_supplier!.notes}',
                              style: const TextStyle(fontStyle: FontStyle.italic, color: AppTheme.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Balance Card Widget
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: hasDebt ? Colors.orange.withValues(alpha: 0.1) : AppTheme.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasDebt ? Colors.orange.withValues(alpha: 0.4) : AppTheme.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            hasDebt ? 'الرصيد المستحق للمورد (له)' : 'الحساب خالص',
                            style: TextStyle(
                              color: hasDebt ? Colors.orange.shade900 : AppTheme.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_supplier!.totalBalance.toStringAsFixed(2)} ج',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: hasDebt ? Colors.orange.shade900 : AppTheme.success,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => _showPaymentDialog(context),
                            icon: const Icon(Icons.payment, size: 18),
                            label: const Text('تسجيل سداد للمورد'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Transactions Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'سجل الفواتير والمدفوعات',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'عدد الحركات: ${_transactions.length}',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Transactions Table
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _transactions.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(48.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.history, size: 48, color: AppTheme.textSecondary),
                              SizedBox(height: 12),
                              Text('لا توجد معاملات مسجلة لهذا المورد حتى الآن'),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(AppTheme.background),
                            columns: const [
                              DataColumn(label: Text('التاريخ والوقت', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('نوع الحركة', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('المبلغ', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('الرصيد قبل', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('الرصيد بعد', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('البيان / ملاحظات', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: _transactions.map((tx) {
                              final isPayment = tx.transactionType == 'payment';
                              return DataRow(
                                cells: [
                                  DataCell(Text(dateFormat.format(tx.createdAt))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isPayment
                                            ? AppTheme.success.withValues(alpha: 0.12)
                                            : Colors.blue.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        tx.typeLabel,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isPayment ? AppTheme.success : Colors.blue.shade800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '${isPayment ? '-' : '+'}${tx.amount.abs().toStringAsFixed(2)} ج',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isPayment ? AppTheme.success : Colors.orange.shade900,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text('${tx.balanceBefore.toStringAsFixed(2)} ج')),
                                  DataCell(
                                    Text(
                                      '${tx.balanceAfter.toStringAsFixed(2)} ج',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataCell(Text(tx.notes ?? '-')),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    final amountController = TextEditingController();
    final notesController = TextEditingController(text: 'سداد نقدي للمورد');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('تسجيل سداد للمورد: ${_supplier!.name}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الرصيد المستحق له: ${_supplier!.totalBalance.toStringAsFixed(2)} ج',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'المبلغ المدفوع (ج)*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات / رقم إيصال الصرف',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('الرجاء إدخال مبلغ صحيح')),
                );
                return;
              }

              final success = await context.read<SuppliersCubit>().addPayment(
                    supplierId: _supplier!.id,
                    amount: amount,
                    notes: notesController.text.trim(),
                  );

              if (mounted) {
                Navigator.pop(dialogCtx);
                if (success) {
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تسجيل السداد وخصم المبلغ من الخزينة بنجاح')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد السداد والخصم من الخزينة'),
          ),
        ],
      ),
    );
  }
}
