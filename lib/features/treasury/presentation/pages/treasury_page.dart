import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/treasury_cubit.dart';
import '../../domain/entities/treasury_entity.dart';

class TreasuryPage extends StatefulWidget {
  const TreasuryPage({super.key});

  @override
  State<TreasuryPage> createState() => _TreasuryPageState();
}

class _TreasuryPageState extends State<TreasuryPage> {
  String? _selectedFilterType;

  @override
  void initState() {
    super.initState();
    context.read<TreasuryCubit>().loadTreasury();
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إدارة الخزينة والسيولة النقدية',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'متابعة حركة النقدية، الإيداعات، السحوبات، والورديات اليومية',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showMovementDialog(context, isDeposit: false),
                      icon: const Icon(Icons.arrow_upward, color: AppTheme.error),
                      label: const Text('سحب نقدي (صرف)', style: TextStyle(color: AppTheme.error)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.error),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showMovementDialog(context, isDeposit: true),
                      icon: const Icon(Icons.arrow_downward),
                      label: const Text('إيداع نقدي بالخزينة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Top Status Cards: Cash Balance & Shift Session
            BlocBuilder<TreasuryCubit, TreasuryState>(
              builder: (context, state) {
                if (state is TreasuryLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is TreasuryLoaded) {
                  final session = state.activeSession;

                  return Row(
                    children: [
                      // Balance Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primary, Color(0xFF1E3A8A)],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.account_balance_wallet, color: Colors.white70, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'رصيد الخزينة الحالي المتوفر',
                                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${state.currentBalance.toStringAsFixed(2)} ج',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Shift / Session Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        session != null ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                                        color: session != null ? AppTheme.success : AppTheme.textSecondary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        session != null ? 'الوردية الحالية: مفتوحة' : 'الوردية الحالية: مغلقة',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: session != null ? AppTheme.success : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (session != null) ...[
                                    Text('فتحت بتاريخ: ${dateFormat.format(session.openedAt)}', style: const TextStyle(fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text('رصيد الافتتاح: ${session.openingBalance.toStringAsFixed(2)} ج', style: const TextStyle(fontSize: 12)),
                                  ] else
                                    const Text('اضغط لبدء تسجيل وردية وكاشير جديدة'),
                                ],
                              ),
                              if (session != null)
                                ElevatedButton.icon(
                                  onPressed: () => _showCloseSessionDialog(context, session),
                                  icon: const Icon(Icons.lock_clock, size: 18),
                                  label: const Text('تقفيل الوردية'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.error,
                                    foregroundColor: Colors.white,
                                  ),
                                )
                              else
                                ElevatedButton.icon(
                                  onPressed: () => _showOpenSessionDialog(context),
                                  icon: const Icon(Icons.play_arrow, size: 18),
                                  label: const Text('فتح وردية جديدة'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return const SizedBox();
              },
            ),
            const SizedBox(height: 24),

            // Ledger Filter and Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'دفتر حركات الخزينة المالي',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                DropdownButton<String?>(
                  value: _selectedFilterType,
                  hint: const Text('جميع أنواع الحركات'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('جميع الحركات')),
                    DropdownMenuItem(value: 'sale_income', child: Text('إيرادات مبيعات')),
                    DropdownMenuItem(value: 'customer_payment', child: Text('تحصيلات عملاء')),
                    DropdownMenuItem(value: 'purchase_payment', child: Text('سداد مشتريات')),
                    DropdownMenuItem(value: 'supplier_payment', child: Text('سداد موردين')),
                    DropdownMenuItem(value: 'expense', child: Text('مصروفات')),
                    DropdownMenuItem(value: 'cash_in', child: Text('إيداعات يدوية')),
                    DropdownMenuItem(value: 'cash_out', child: Text('سحوبات يدوية')),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedFilterType = val);
                    context.read<TreasuryCubit>().loadTreasury(type: val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Ledger Table
            Expanded(
              child: BlocBuilder<TreasuryCubit, TreasuryState>(
                builder: (context, state) {
                  if (state is TreasuryLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is TreasuryLoaded) {
                    if (state.transactions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            const Text('لا توجد حركات نقدية مسجلة'),
                          ],
                        ),
                      );
                    }

                    return Container(
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
                                DataColumn(label: Text('التاريخ والوقت', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('نوع الحركة', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('المبلغ', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('الرصيد قبل', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('الرصيد بعد', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('البيان / الوصف', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: state.transactions.map((tx) {
                                final isPlus = tx.amount > 0;

                                return DataRow(
                                  cells: [
                                    DataCell(Text(dateFormat.format(tx.createdAt))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isPlus ? AppTheme.success.withValues(alpha: 0.12) : AppTheme.error.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          tx.typeLabel,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isPlus ? AppTheme.success : AppTheme.error,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '${isPlus ? '+' : ''}${tx.amount.toStringAsFixed(2)} ج',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isPlus ? AppTheme.success : AppTheme.error,
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
                                    DataCell(Text(tx.description)),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
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

  void _showMovementDialog(BuildContext context, {required bool isDeposit}) {
    final amountController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isDeposit ? 'إيداع نقدي بالخزينة' : 'سحب نقدي من الخزينة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'المبلغ (ج)*',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: isDeposit ? 'سبب الإيداع / المصدر *' : 'سبب السحب / الغرض *',
                prefixIcon: const Icon(Icons.description_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amountController.text) ?? 0.0;
              final desc = descController.text.trim();
              if (amt <= 0 || desc.isEmpty) return;

              Navigator.pop(ctx);
              final success = await context.read<TreasuryCubit>().addCashMovement(
                    amount: isDeposit ? amt : -amt,
                    type: isDeposit ? 'cash_in' : 'cash_out',
                    description: desc,
                  );

              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isDeposit ? 'تم تسجيل الإيداع بنجاح' : 'تم تسجيل السحب بنجاح'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDeposit ? AppTheme.success : AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text(isDeposit ? 'تأكيد الإيداع' : 'تأكيد السحب'),
          ),
        ],
      ),
    );
  }

  void _showOpenSessionDialog(BuildContext context) {
    final amountController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('بدء وفتح وردية كاشير جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'رصيد الافتتاح (عهدة الصندوق)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amountController.text) ?? 0.0;
              Navigator.pop(ctx);
              await context.read<TreasuryCubit>().openSession(amt);
            },
            child: const Text('فتح الوردية'),
          ),
        ],
      ),
    );
  }

  void _showCloseSessionDialog(BuildContext context, CashSessionEntity session) {
    final actualController = TextEditingController(text: session.expectedBalance.toString());
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تقفيل وإنهاء الوردية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الرصيد الدفتري المتوقع بالدرج: ${session.expectedBalance.toStringAsFixed(2)} ج',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
            const SizedBox(height: 16),
            TextField(
              controller: actualController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'الرصيد الفعلي بعد الجرد في الدرج (ج)*',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات التسليم والتقفيل',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final actual = double.tryParse(actualController.text) ?? session.expectedBalance;
              Navigator.pop(ctx);
              await context.read<TreasuryCubit>().closeSession(
                    session.id,
                    actual,
                    notes: notesController.text.trim(),
                  );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            child: const Text('تقفيل واعتماد الوردية'),
          ),
        ],
      ),
    );
  }
}
