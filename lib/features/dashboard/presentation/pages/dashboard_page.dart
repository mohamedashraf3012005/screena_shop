import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_routes.dart';
import '../cubit/dashboard_cubit.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE، d MMMM yyyy', 'ar');
    final todayFormatted = dateFormat.format(DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Welcome & Date Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً بك في نظام Screena Shop 👋',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      todayFormatted,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.pos),
                  icon: const Icon(Icons.point_of_sale_rounded, size: 22),
                  label: const Text('فتح نقطة البيع (POS)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main KPI Cards
            BlocBuilder<DashboardCubit, DashboardState>(
              builder: (context, state) {
                if (state is DashboardLoading) {
                  return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
                }

                if (state is DashboardError) {
                  return Center(
                    child: Column(
                      children: [
                        Text(state.message, style: const TextStyle(color: AppTheme.error)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => context.read<DashboardCubit>().loadDashboard(),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is DashboardLoaded) {
                  final stats = state.todayStats;
                  final todaySales = stats['today_sales'] ?? 0.0;
                  final todayProfit = stats['today_profit'] ?? 0.0;
                  final cashBal = stats['cash_balance'] ?? 0.0;
                  final invoicesCount = (stats['invoice_count'] ?? 0.0).toInt();
                  final lowStockCount = state.lowStockProducts.length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 4 KPI Cards
                      Row(
                        children: [
                          _buildKpiCard(
                            title: 'مبيعات اليوم',
                            value: '${todaySales.toStringAsFixed(2)} ج',
                            subtitle: '$invoicesCount فاتورة بيع اليوم',
                            icon: Icons.shopping_bag_outlined,
                            gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          ),
                          const SizedBox(width: 16),
                          _buildKpiCard(
                            title: 'أرباح اليوم التقديرية',
                            value: '${todayProfit.toStringAsFixed(2)} ج',
                            subtitle: 'هامش ربح مبيعات اليوم',
                            icon: Icons.trending_up,
                            gradient: const [Color(0xFF059669), Color(0xFF047857)],
                          ),
                          const SizedBox(width: 16),
                          _buildKpiCard(
                            title: 'رصيد الخزينة الحالي',
                            value: '${cashBal.toStringAsFixed(2)} ج',
                            subtitle: 'السيولة النقدية المتاحة بالصندوق',
                            icon: Icons.account_balance_wallet_outlined,
                            gradient: const [Color(0xFF4F46E5), Color(0xFF3730A3)],
                          ),
                          const SizedBox(width: 16),
                          _buildKpiCard(
                            title: 'تنبيهات النواقص',
                            value: '$lowStockCount صنف',
                            subtitle: 'أصناف بلغت الحد الأدنى للطلب',
                            icon: Icons.warning_amber_rounded,
                            gradient: lowStockCount > 0
                                ? [const Color(0xFFDC2626), const Color(0xFF991B1B)]
                                : [const Color(0xFF4B5563), const Color(0xFF374151)],
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Quick Actions Bar
                      Text(
                        'إجراءات سريعة',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildQuickActionButton(
                            icon: Icons.add_box_outlined,
                            label: 'إضافة صنف جديد',
                            color: Colors.blue,
                            onTap: () => context.go(AppRoutes.productAdd),
                          ),
                          const SizedBox(width: 12),
                          _buildQuickActionButton(
                            icon: Icons.add_shopping_cart,
                            label: 'فاتورة شراء من مورد',
                            color: Colors.teal,
                            onTap: () => context.go(AppRoutes.purchaseAdd),
                          ),
                          const SizedBox(width: 12),
                          _buildQuickActionButton(
                            icon: Icons.person_add_outlined,
                            label: 'إضافة عميل',
                            color: Colors.indigo,
                            onTap: () => context.go(AppRoutes.customerAdd),
                          ),
                          const SizedBox(width: 12),
                          _buildQuickActionButton(
                            icon: Icons.attach_money,
                            label: 'تسجيل مصروف',
                            color: Colors.orange,
                            onTap: () => context.go(AppRoutes.expenses),
                          ),
                          const SizedBox(width: 12),
                          _buildQuickActionButton(
                            icon: Icons.inventory_2_outlined,
                            label: 'جرد وتسوية المخزون',
                            color: Colors.purple,
                            onTap: () => context.go(AppRoutes.stockAdjustment),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Financial Health & Valuation
                      Row(
                        children: [
                          _buildFinancialHealthCard(
                            title: 'إجمالي قيمة المخزون (بالتكلفة)',
                            value: '${state.totalInventoryValuation.toStringAsFixed(2)} ج',
                            icon: Icons.inventory_2,
                            color: Colors.teal,
                          ),
                          const SizedBox(width: 16),
                          _buildFinancialHealthCard(
                            title: 'إجمالي مديونيات العملاء لنا',
                            value: '${state.totalCustomerDebt.toStringAsFixed(2)} ج',
                            icon: Icons.people_alt,
                            color: Colors.blue.shade800,
                          ),
                          const SizedBox(width: 16),
                          _buildFinancialHealthCard(
                            title: 'إجمالي مستحقات الموردين علينا',
                            value: '${state.totalSupplierDebt.toStringAsFixed(2)} ج',
                            icon: Icons.local_shipping,
                            color: Colors.amber.shade900,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Low Stock Alert Table
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'تنبيهات الأصناف المنخفضة بالمخزن',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.inventory),
                            child: const Text('عرض إدارة المخزون كاملة'),
                          ),
                        ],
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
                          child: state.lowStockProducts.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle, color: AppTheme.success),
                                        SizedBox(width: 8),
                                        Text('المخزون في حالة ممتازة، لا توجد نواقص تحت حد الطلب'),
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
                                        DataColumn(label: Text('اسم الصنف', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('الباركود', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('الرصيد المتبقي', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('الحد الأدنى', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('الإجراء', style: TextStyle(fontWeight: FontWeight.bold))),
                                      ],
                                      rows: state.lowStockProducts.take(8).map((p) {
                                        final isOut = p.currentQuantity <= 0;
                                        return DataRow(
                                          cells: [
                                            DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                                            DataCell(Text(p.barcode ?? '-')),
                                            DataCell(
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: isOut ? AppTheme.error.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${p.currentQuantity} ${p.unit}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: isOut ? AppTheme.error : Colors.orange.shade900,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(Text('${p.minQuantity} ${p.unit}')),
                                            DataCell(
                                              ElevatedButton(
                                                onPressed: () => context.go(AppRoutes.purchaseAdd),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppTheme.primary,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                ),
                                                child: const Text('طلب شراء'),
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
                  );
                }

                return const SizedBox();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topRight, end: Alignment.bottomLeft),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: gradient.first.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                Icon(icon, color: Colors.white70, size: 22),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.border),
        ),
        color: AppTheme.cardBackground,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  foregroundColor: color,
                  radius: 20,
                  child: Icon(icon, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialHealthCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              foregroundColor: color,
              radius: 24,
              child: Icon(icon, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
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
