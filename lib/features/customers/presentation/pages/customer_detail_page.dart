import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_routes.dart';
import '../cubit/customers_cubit.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerDetailPage extends StatefulWidget {
  final int customerId;

  const CustomerDetailPage({super.key, required this.customerId});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  CustomerEntity? _customer;
  List<CustomerTransactionEntity> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final cubit = context.read<CustomersCubit>();
    final customer = await cubit.getById(widget.customerId);
    final transactions = await cubit.getTransactions(widget.customerId);

    if (mounted) {
      setState(() {
        _customer = customer;
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

    if (_customer == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('كشف حساب العميل')),
        body: const Center(child: Text('العميل غير موجود')),
      );
    }

    final hasDebt = _customer!.totalBalance > 0;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('كشف حساب العميل: ${_customer!.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.customers),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'تعديل البيانات',
            onPressed: () => context.go('/customers/${_customer!.id}/edit'),
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
            // Top Customer Profile Card
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
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                      foregroundColor: AppTheme.primary,
                      child: const Icon(Icons.person, size: 40),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _customer!.name,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _customer!.isActive ? AppTheme.success.withValues(alpha: 0.12) : AppTheme.border,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _customer!.isActive ? 'نشط' : 'معطل',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _customer!.isActive ? AppTheme.success : AppTheme.textSecondary,
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
                              if (_customer!.phone != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.phone, size: 16, color: AppTheme.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(_customer!.phone!, style: const TextStyle(color: AppTheme.textSecondary)),
                                  ],
                                ),
                              if (_customer!.whatsapp != null)
                                InkWell(
                                  onTap: () => _launchWhatsApp(_customer!.whatsapp!),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.chat, size: 16, color: Colors.green),
                                      const SizedBox(width: 6),
                                      Text(
                                        _customer!.whatsapp!,
                                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.open_in_new, size: 12, color: Colors.green),
                                    ],
                                  ),
                                ),
                              if (_customer!.address != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on, size: 16, color: AppTheme.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(_customer!.address!, style: const TextStyle(color: AppTheme.textSecondary)),
                                  ],
                                ),
                            ],
                          ),
                          if (_customer!.notes != null && _customer!.notes!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              'ملاحظات: ${_customer!.notes}',
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
                        color: hasDebt ? AppTheme.error.withValues(alpha: 0.08) : AppTheme.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasDebt ? AppTheme.error.withValues(alpha: 0.3) : AppTheme.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            hasDebt ? 'المديونية المستحقة (عليه)' : 'الرصيد خالص',
                            style: TextStyle(
                              color: hasDebt ? AppTheme.error : AppTheme.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_customer!.totalBalance.toStringAsFixed(2)} ج',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: hasDebt ? AppTheme.error : AppTheme.success,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => _showPaymentDialog(context),
                            icon: const Icon(Icons.payment, size: 18),
                            label: const Text('تسجيل تحصيل / دفعة'),
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
                  'سجل المعاملات والحركات المالية',
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
                              Text('لا توجد معاملات مسجلة لهذا العميل حتى الآن'),
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
                                            : AppTheme.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        tx.typeLabel,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isPayment ? AppTheme.success : AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '${isPayment ? '-' : '+'}${tx.amount.toStringAsFixed(2)} ج',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isPayment ? AppTheme.success : AppTheme.error,
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
    final notesController = TextEditingController(text: 'تحصيل دفعة نقدية');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('تسجيل تحصيل من: ${_customer!.name}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'المديونية الحالية: ${_customer!.totalBalance.toStringAsFixed(2)} ج',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'المبلغ المحصل (ج)*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات / رقم الإيصال',
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

              final success = await context.read<CustomersCubit>().addPayment(
                    customerId: _customer!.id,
                    amount: amount,
                    notes: notesController.text.trim(),
                  );

              if (mounted) {
                Navigator.pop(dialogCtx);
                if (success) {
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تسجيل التحصيل وتحديث الخزينة')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('حفظ التحصيل'),
          ),
        ],
      ),
    );
  }
}
