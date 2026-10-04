import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/expenses_cubit.dart';
import '../../domain/entities/expense_entity.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  String? _selectedCategory;

  final List<String> _categories = [
    'إيجار',
    'كهرباء',
    'مياه',
    'مرتبات',
    'بوفيه ونظافة',
    'صيانة',
    'نقل وشحن',
    'دعاية وإعلان',
    'أخرى',
  ];

  @override
  void initState() {
    super.initState();
    context.read<ExpensesCubit>().loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');

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
                      'المصروفات العامة والتشغيلية',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تسجيل النثريات والمصروفات اليومية والشهرية وخصمها من الخزينة',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddExpenseDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('تسجيل مصروف جديد'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Category Totals Cards
            BlocBuilder<ExpensesCubit, ExpensesState>(
              builder: (context, state) {
                if (state is ExpensesLoaded && state.categoryTotals.isNotEmpty) {
                  return Container(
                    height: 100,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Total Card
                        Container(
                          width: 200,
                          margin: const EdgeInsets.only(left: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFE11D48), Color(0xFF9F1239)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('إجمالي المصروفات', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                              Text(
                                '${state.totalAmount.toStringAsFixed(2)} ج',
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        ...state.categoryTotals.entries.map((entry) {
                          return Container(
                            width: 170,
                            margin: const EdgeInsets.only(left: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  '${entry.value.toStringAsFixed(2)} ج',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.error),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }
                return const SizedBox();
              },
            ),

            // Filter Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Text('تصفية حسب التصنيف:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  DropdownButton<String?>(
                    value: _selectedCategory,
                    hint: const Text('جميع التصنيفات'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('جميع التصنيفات')),
                      ..._categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedCategory = val);
                      context.read<ExpensesCubit>().loadExpenses(category: val);
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'تحديث',
                    onPressed: () {
                      setState(() => _selectedCategory = null);
                      context.read<ExpensesCubit>().loadExpenses();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Expenses Table
            Expanded(
              child: BlocBuilder<ExpensesCubit, ExpensesState>(
                builder: (context, state) {
                  if (state is ExpensesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is ExpensesError) {
                    return Center(child: Text(state.message));
                  }

                  if (state is ExpensesLoaded) {
                    if (state.expenses.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.money_off_csred_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            const Text('لا توجد مصروفات مسجلة'),
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
                                DataColumn(label: Text('م', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('التصنيف', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('البيان / الوصف', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('المبلغ', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('ملاحظات', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: state.expenses.asMap().entries.map((entry) {
                                final index = entry.key + 1;
                                final e = entry.value;

                                return DataRow(
                                  cells: [
                                    DataCell(Text('$index')),
                                    DataCell(Text(dateFormat.format(e.expenseDate))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(e.category, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                      ),
                                    ),
                                    DataCell(Text(e.description)),
                                    DataCell(
                                      Text(
                                        '${e.amount.toStringAsFixed(2)} ج',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error),
                                      ),
                                    ),
                                    DataCell(Text(e.notes ?? '-')),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                                        tooltip: 'حذف المصروف واسترداد المبلغ للخزينة',
                                        onPressed: () => _confirmDelete(context, e),
                                      ),
                                    ),
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

  void _showAddExpenseDialog(BuildContext context) {
    String selectedCategory = _categories.first;
    final amountController = TextEditingController();
    final descController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('تسجيل مصروف جديد'),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(labelText: 'تصنيف المصروف *', border: OutlineInputBorder()),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCategory = val);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'المبلغ (ج)*',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'البيان / الوصف *',
                    hintText: 'مثال: فاتورة كهرباء شهر 9، شراء منظفات...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات إضافية',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amountController.text) ?? 0.0;
                final desc = descController.text.trim();
                if (amt <= 0 || desc.isEmpty) return;

                Navigator.pop(ctx);
                final expense = ExpenseEntity(
                  id: 0,
                  category: selectedCategory,
                  description: desc,
                  amount: amt,
                  paymentMethod: 'cash',
                  notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  expenseDate: DateTime.now(),
                  createdAt: DateTime.now(),
                );

                await context.read<ExpensesCubit>().createExpense(expense);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              child: const Text('حفظ وخصم من الخزينة'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ExpenseEntity expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف هذا المصروف بقيمة ${expense.amount} ج واسترداده إلى الخزينة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ExpensesCubit>().deleteExpense(expense.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            child: const Text('حذف واسترداد'),
          ),
        ],
      ),
    );
  }
}
