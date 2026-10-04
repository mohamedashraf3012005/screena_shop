import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_routes.dart';
import '../cubit/suppliers_cubit.dart';
import '../../domain/entities/supplier_entity.dart';

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key});

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SuppliersCubit>().loadSuppliers();
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
                      'إدارة الموردين',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'متابعة حسابات الموردين والشركات ومستحقات المشتريات',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.supplierAdd),
                  icon: const Icon(Icons.add_business_rounded),
                  label: const Text('إضافة مورد جديد'),
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
                        context.read<SuppliersCubit>().loadSuppliers(search: val);
                      },
                      decoration: InputDecoration(
                        hintText: 'البحث باسم المورد، اسم الشركة، أو الهاتف...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  context.read<SuppliersCubit>().loadSuppliers();
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
                      context.read<SuppliersCubit>().loadSuppliers();
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

            // Suppliers Table / List
            Expanded(
              child: BlocBuilder<SuppliersCubit, SuppliersState>(
                builder: (context, state) {
                  if (state is SuppliersLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is SuppliersError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                          const SizedBox(height: 12),
                          Text(state.message, style: TextStyle(color: AppTheme.error)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context.read<SuppliersCubit>().loadSuppliers(),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is SuppliersLoaded) {
                    if (state.suppliers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_shipping_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            const Text(
                              'لا يوجد موردين مسجلين',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text('يمكنك إضافة مورد جديد باستخدام الزر أعلاه'),
                          ],
                        ),
                      );
                    }

                    final totalDebt = state.suppliers.fold<double>(0, (sum, s) => sum + s.totalBalance);

                    return Column(
                      children: [
                        // Quick Stats Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'إجمالي عدد الموردين: ${state.suppliers.length}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Text(
                                'إجمالي المستحق للموردين: ${totalDebt.toStringAsFixed(2)} ج',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: totalDebt > 0 ? Colors.orange.shade800 : AppTheme.success,
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
                                      DataColumn(label: Text('اسم المورد', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('الشركة', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('الهاتف', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('المستحق له (الرصيد)', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: state.suppliers.asMap().entries.map((entry) {
                                      final index = entry.key + 1;
                                      final supplier = entry.value;
                                      final hasDebt = supplier.totalBalance > 0;

                                      return DataRow(
                                        cells: [
                                          DataCell(Text('$index')),
                                          DataCell(
                                            InkWell(
                                              onTap: () => context.go('${AppRoutes.suppliers}/${supplier.id}'),
                                              child: Text(
                                                supplier.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primary,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(supplier.company ?? '-')),
                                          DataCell(Text(supplier.phone ?? '-')),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: hasDebt
                                                    ? Colors.orange.withValues(alpha: 0.15)
                                                    : AppTheme.success.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '${supplier.totalBalance.toStringAsFixed(2)} ج',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: hasDebt ? Colors.orange.shade900 : AppTheme.success,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              supplier.isActive ? 'نشط' : 'معطل',
                                              style: TextStyle(
                                                color: supplier.isActive ? AppTheme.success : AppTheme.textSecondary,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.payment_outlined, size: 20),
                                                  tooltip: 'سداد دفعة للمورد',
                                                  color: Colors.green,
                                                  onPressed: () => _showPaymentDialog(context, supplier),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.receipt_long_outlined, size: 20),
                                                  tooltip: 'كشف حساب',
                                                  onPressed: () => context.go('${AppRoutes.suppliers}/${supplier.id}'),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                                  tooltip: 'تعديل',
                                                  onPressed: () => context.go('/suppliers/${supplier.id}/edit'),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, size: 20),
                                                  color: AppTheme.error,
                                                  tooltip: 'حذف',
                                                  onPressed: () => _confirmDelete(context, supplier),
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

  void _showPaymentDialog(BuildContext context, SupplierEntity supplier) {
    final amountController = TextEditingController();
    final notesController = TextEditingController(text: 'سداد نقدي من الحساب');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('تسجيل سداد للمورد: ${supplier.name}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الرصيد المستحق له: ${supplier.totalBalance.toStringAsFixed(2)} ج',
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
                    supplierId: supplier.id,
                    amount: amount,
                    notes: notesController.text.trim(),
                  );

              if (mounted) {
                Navigator.pop(dialogCtx);
                if (success) {
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

  void _confirmDelete(BuildContext context, SupplierEntity supplier) {
    if (supplier.totalBalance > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تنبيه'),
          content: Text('لا يمكن حذف المورد (${supplier.name}) لأن له رصيد مستحق قدره ${supplier.totalBalance.toStringAsFixed(2)} ج.'),
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
        content: Text('هل أنت متأكد من حذف المورد "${supplier.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<SuppliersCubit>().delete(supplier.id);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف المورد بنجاح')),
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
