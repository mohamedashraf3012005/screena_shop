import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/reports_cubit.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _selectedPeriod = 'all';

  @override
  void initState() {
    super.initState();
    context.read<ReportsCubit>().loadReport();
  }

  void _onPeriodChanged(String period) {
    setState(() => _selectedPeriod = period);
    final now = DateTime.now();

    DateTime? fromDate;
    DateTime? toDate;

    if (period == 'today') {
      fromDate = DateTime(now.year, now.month, now.day);
      toDate = fromDate.add(const Duration(days: 1));
    } else if (period == 'week') {
      fromDate = now.subtract(Duration(days: now.weekday - 1));
      fromDate = DateTime(fromDate.year, fromDate.month, fromDate.day);
      toDate = now;
    } else if (period == 'month') {
      fromDate = DateTime(now.year, now.month, 1);
      toDate = now;
    }

    context.read<ReportsCubit>().loadReport(fromDate: fromDate, toDate: toDate);
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
                      'التقارير المالية والأرباح',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'بيان الأرباح والخسائر، تقييم المخزون، والديون والمستحقات',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
                // Period Selector
                Row(
                  children: [
                    _buildPeriodChip('all', 'كل الفترات'),
                    const SizedBox(width: 8),
                    _buildPeriodChip('month', 'هذا الشهر'),
                    const SizedBox(width: 8),
                    _buildPeriodChip('week', 'هذا الأسبوع'),
                    const SizedBox(width: 8),
                    _buildPeriodChip('today', 'اليوم'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content
            Expanded(
              child: BlocBuilder<ReportsCubit, ReportsState>(
                builder: (context, state) {
                  if (state is ReportsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is ReportsError) {
                    return Center(child: Text(state.message));
                  }

                  if (state is ReportsLoaded) {
                    final f = state.financial;

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Net Profit Highlight Banner
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: f.netProfit >= 0
                                    ? [const Color(0xFF10B981), const Color(0xFF047857)]
                                    : [const Color(0xFFEF4444), const Color(0xFFB91C1C)],
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'صافي الربح التشغيلي الحقيقي (بعد خصم المصروفات والهالك)',
                                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${f.netProfit.toStringAsFixed(2)} ج',
                                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    f.netProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Income & Expense Grid
                          Row(
                            children: [
                              _buildMetricCard(
                                title: 'إجمالي المبيعات',
                                value: '${f.totalSales.toStringAsFixed(2)} ج',
                                icon: Icons.shopping_bag_outlined,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 16),
                              _buildMetricCard(
                                title: 'مجمل ربح البضاعة',
                                value: '${f.grossProfit.toStringAsFixed(2)} ج',
                                icon: Icons.payments_outlined,
                                color: AppTheme.success,
                              ),
                              const SizedBox(width: 16),
                              _buildMetricCard(
                                title: 'إجمالي المصروفات',
                                value: '${f.totalExpenses.toStringAsFixed(2)} ج',
                                icon: Icons.money_off,
                                color: AppTheme.error,
                              ),
                              const SizedBox(width: 16),
                              _buildMetricCard(
                                title: 'خسارة الهالك والتالف',
                                value: '${f.totalDamagesCost.toStringAsFixed(2)} ج',
                                icon: Icons.delete_outline,
                                color: Colors.orange.shade800,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Financial Health & Balances
                          Text(
                            'المركز المالي والأصول والديون الحالية',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildMetricCard(
                                title: 'السيولة في الخزينة',
                                value: '${f.currentCashBalance.toStringAsFixed(2)} ج',
                                icon: Icons.account_balance_wallet_outlined,
                                color: Colors.indigo,
                              ),
                              const SizedBox(width: 16),
                              _buildMetricCard(
                                title: 'قيمة المخزون (بالتكلفة)',
                                value: '${f.totalInventoryValuation.toStringAsFixed(2)} ج',
                                icon: Icons.inventory_2_outlined,
                                color: Colors.teal,
                              ),
                              const SizedBox(width: 16),
                              _buildMetricCard(
                                title: 'مديونيات العملاء لنا',
                                value: '${f.totalCustomersDebt.toStringAsFixed(2)} ج',
                                icon: Icons.people_outline,
                                color: Colors.blue.shade800,
                              ),
                              const SizedBox(width: 16),
                              _buildMetricCard(
                                title: 'مستحقات الموردين علينا',
                                value: '${f.totalSuppliersDebt.toStringAsFixed(2)} ج',
                                icon: Icons.local_shipping_outlined,
                                color: Colors.amber.shade900,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Top Selling Products
                          Text(
                            'الأصناف الأكثر مبيعاً وتحقيقاً للإيراد',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: state.topProducts.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(32.0),
                                      child: Center(child: Text('لا توجد مبيعات في الفترة المحددة')),
                                    )
                                  : SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: DataTable(
                                          headingRowColor: WidgetStateProperty.all(AppTheme.background),
                                          columns: const [
                                            DataColumn(label: Text('م', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('اسم الصنف', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('الكمية المباعة', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('إجمالي الإيراد', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('إجمالي الربح المحقق', style: TextStyle(fontWeight: FontWeight.bold))),
                                          ],
                                          rows: state.topProducts.asMap().entries.map((entry) {
                                            final index = entry.key + 1;
                                            final p = entry.value;

                                            return DataRow(
                                              cells: [
                                                DataCell(Text('$index')),
                                                DataCell(Text(p.productName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                                DataCell(Text('${p.quantitySold}')),
                                                DataCell(Text('${p.totalRevenue.toStringAsFixed(2)} ج')),
                                                DataCell(
                                                  Text(
                                                    '${p.totalProfit.toStringAsFixed(2)} ج',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success),
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
                        ],
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

  Widget _buildPeriodChip(String id, String label) {
    final isSelected = _selectedPeriod == id;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onPeriodChanged(id),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              foregroundColor: color,
              radius: 22,
              child: Icon(icon, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
