import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_routes.dart';
import '../cubit/customers_cubit.dart';
import '../../domain/entities/customer_entity.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CustomersCubit>().loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      'إدارة العملاء',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'عرض ومتابعة حسابات وديون العملاء والتحصيل',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.customerAdd),
                  icon: const Icon(Icons.person_add_rounded),
                  label: const Text('إضافة عميل جديد'),
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

            // Search Bar & Filters
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
                        context.read<CustomersCubit>().loadCustomers(search: val);
                      },
                      decoration: InputDecoration(
                        hintText: 'البحث باسم العميل أو رقم الهاتف...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  context.read<CustomersCubit>().loadCustomers();
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
                      context.read<CustomersCubit>().loadCustomers();
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

            // Customers Table / List
            Expanded(
              child: BlocBuilder<CustomersCubit, CustomersState>(
                builder: (context, state) {
                  if (state is CustomersLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is CustomersError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                          const SizedBox(height: 12),
                          Text(state.message, style: TextStyle(color: AppTheme.error)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context.read<CustomersCubit>().loadCustomers(),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is CustomersLoaded) {
                    if (state.customers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            const Text(
                              'لا يوجد عملاء حالياً',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text('يمكنك إضافة عميل جديد باستخدام الزر أعلاه'),
                          ],
                        ),
                      );
                    }

                    final totalDebt = state.customers.fold<double>(0, (sum, c) => sum + c.totalBalance);

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
                                'إجمالي عدد العملاء: ${state.customers.length}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Text(
                                'إجمالي المديونية المستحقة: ${totalDebt.toStringAsFixed(2)} ج',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: totalDebt > 0 ? AppTheme.error : AppTheme.success,
                                ),
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
                                      DataColumn(label: Text('م', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('اسم العميل', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('الهاتف', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('العنوان', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('المديونية الحالية', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: state.customers.asMap().entries.map((entry) {
                                      final index = entry.key + 1;
                                      final customer = entry.value;
                                      final hasDebt = customer.totalBalance > 0;

                                      return DataRow(
                                        cells: [
                                          DataCell(Text('$index')),
                                          DataCell(
                                            InkWell(
                                              onTap: () => context.go('${AppRoutes.customers}/${customer.id}'),
                                              child: Text(
                                                customer.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primary,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(customer.phone ?? '-')),
                                          DataCell(Text(customer.address ?? '-')),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: hasDebt
                                                    ? AppTheme.error.withValues(alpha: 0.12)
                                                    : AppTheme.success.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '${customer.totalBalance.toStringAsFixed(2)} ج',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: hasDebt ? AppTheme.error : AppTheme.success,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              customer.isActive ? 'نشط' : 'معطل',
                                              style: TextStyle(
                                                color: customer.isActive ? AppTheme.success : AppTheme.textSecondary,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
                                                  tooltip: 'تسجيل دفعة / تحصيل',
                                                  color: AppTheme.primary,
                                                  onPressed: () => _showPaymentDialog(context, customer),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.remove_red_eye_outlined, size: 20),
                                                  tooltip: 'كشف حساب',
                                                  onPressed: () => context.go('${AppRoutes.customers}/${customer.id}'),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                                  tooltip: 'تعديل',
                                                  onPressed: () => context.go('/customers/${customer.id}/edit'),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, size: 20),
                                                  color: AppTheme.error,
                                                  tooltip: 'حذف',
                                                  onPressed: () => _confirmDelete(context, customer),
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

  void _showPaymentDialog(BuildContext context, CustomerEntity customer) {
    final amountController = TextEditingController();
    final notesController = TextEditingController(text: 'دفعة نقدية من الحساب');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('تسجيل تحصيل من العميل: ${customer.name}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'المديونية الحالية: ${customer.totalBalance.toStringAsFixed(2)} ج',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error),
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
                  labelText: 'ملاحظات / بيان الدفعة',
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
                  const SnackBar(content: Text('الرجاء إدخال مبلغ صحيح أكبر من الصفر')),
                );
                return;
              }

              final success = await context.read<CustomersCubit>().addPayment(
                    customerId: customer.id,
                    amount: amount,
                    notes: notesController.text.trim(),
                  );

              if (mounted) {
                Navigator.pop(dialogCtx);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تسجيل الدفعة وتحديث الخزينة بنجاح')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('حفظ التحصيل وإيداع بالخزينة'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, CustomerEntity customer) {
    if (customer.totalBalance > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تنبيه'),
          content: Text('لا يمكن حذف العميل (${customer.name}) لأن عليه مديونية مستحقة قدرها ${customer.totalBalance.toStringAsFixed(2)} ج.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف العميل "${customer.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<CustomersCubit>().delete(customer.id);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف العميل بنجاح')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
