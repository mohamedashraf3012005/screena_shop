import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/formatters.dart';
import '../cubit/inventory_cubit.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/presentation/cubit/products_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _stockFilter = 'all'; // 'all', 'in_stock', 'low_stock', 'out_of_stock'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<InventoryCubit>().loadInventoryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إدارة المخزون والمستودع',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'مراقبة كميات وأرصدة الأصناف بالمخزن بعدد القطع، سجل الحركات، النواقص، والتوالف',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        final invState = context.read<InventoryCubit>().state;
                        final products = invState is InventoryLoaded ? invState.allProducts : <ProductEntity>[];
                        _showManualStockDialog(context, allProducts: products);
                      },
                      icon: const Icon(Icons.add_box_rounded),
                      label: const Text('إضافة / زيادة رصيد يدوي'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.go(AppRoutes.stockDamage),
                      icon: const Icon(Icons.delete_sweep_outlined, color: AppTheme.error),
                      label: const Text('تسجيل تالف / هالك', style: TextStyle(color: AppTheme.error)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.error),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => context.go(AppRoutes.stockAdjustment),
                      icon: const Icon(Icons.inventory_rounded),
                      label: const Text('جرد المخزون الفعلي'),
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
              ],
            ),
            const SizedBox(height: 20),

            // Tabs Header
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primary,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.inventory_2_outlined),
                    text: 'كل المخزون (أرصدة الأصناف بالقطع)',
                  ),
                  Tab(
                    icon: Icon(Icons.swap_vert),
                    text: 'سجل حركات المخزون',
                  ),
                  Tab(
                    icon: Icon(Icons.warning_amber_rounded),
                    text: 'النواقص وتنبيهات الحد الأدنى',
                  ),
                  Tab(
                    icon: Icon(Icons.delete_outline),
                    text: 'سجل التوالف والهالك',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Views
            Expanded(
              child: BlocBuilder<InventoryCubit, InventoryState>(
                builder: (context, state) {
                  if (state is InventoryLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is InventoryError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                          const SizedBox(height: 12),
                          Text(state.message),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context.read<InventoryCubit>().loadInventoryData(),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is InventoryLoaded) {
                    return TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 0: All Current Stock (by piece count)
                        _buildAllStockTab(state),

                        // Tab 1: Movements
                        _buildMovementsTab(state, dateFormat),

                        // Tab 2: Low Stock
                        _buildLowStockTab(state),

                        // Tab 3: Damages
                        _buildDamagesTab(state, dateFormat),
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

  // ─── TAB 0: ALL STOCK (الأرصدة الحالية بعدد القطع) ───
  Widget _buildAllStockTab(InventoryLoaded state) {
    final all = state.allProducts;
    final totalItems = all.length;
    final totalPieces = all.fold<double>(0, (sum, p) => sum + p.currentQuantity);
    final totalCostValue = all.fold<double>(0, (sum, p) => sum + (p.currentQuantity * p.costPrice));
    final outOfStockCount = all.where((p) => p.isOutOfStock).length;
    final lowStockCount = all.where((p) => p.isLowStock && !p.isOutOfStock).length;
    final inStockCount = all.where((p) => p.currentQuantity > 0).length;

    // Filter products
    final filtered = all.where((p) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = p.name.toLowerCase().contains(q);
        final matchesBarcode = p.barcode?.toLowerCase().contains(q) ?? false;
        final matchesCategory = p.categoryName?.toLowerCase().contains(q) ?? false;
        final matchesType = p.productTypeName?.toLowerCase().contains(q) ?? false;
        if (!matchesName && !matchesBarcode && !matchesCategory && !matchesType) {
          return false;
        }
      }
      if (_stockFilter == 'in_stock') {
        return p.currentQuantity > 0;
      } else if (_stockFilter == 'low_stock') {
        return p.isLowStock && !p.isOutOfStock;
      } else if (_stockFilter == 'out_of_stock') {
        return p.isOutOfStock;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPI Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'إجمالي عدد القطع بالمخزن',
                value: '${totalPieces.toStringAsFixed(0)} قطعة',
                subtitle: 'إجمالي الرصيد الفعلي المتوفر بالمكان',
                icon: Icons.layers_rounded,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: 'إجمالي الأصناف المسجلة',
                value: '$totalItems صنف',
                subtitle: '$inStockCount صنف متوفر حالياً',
                icon: Icons.inventory_2_rounded,
                color: const Color(0xFF0284C7),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: 'إجمالي رأس مال المخزون',
                value: CurrencyFormatter.format(totalCostValue),
                subtitle: 'قيمة البضاعة الإجمالية بسعر التكلفة',
                icon: Icons.account_balance_wallet_rounded,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: 'النواقص والمنتهية',
                value: '${outOfStockCount + lowStockCount} صنف',
                subtitle: '$outOfStockCount نافد بالكامل • $lowStockCount منخفض',
                icon: Icons.warning_amber_rounded,
                color: (outOfStockCount + lowStockCount > 0) ? AppTheme.warning : AppTheme.success,
                onTap: () {
                  setState(() {
                    _stockFilter = _stockFilter == 'low_stock' ? 'all' : 'low_stock';
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Filter and Search Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              // Search input
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث في كل المخزون بالاسم أو الباركود...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            }),
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                ),
              ),
              const SizedBox(width: 16),

              // Filter Chips
              _buildFilterBadge('الكل ($totalItems)', 'all'),
              const SizedBox(width: 8),
              _buildFilterBadge('متوفر ($inStockCount)', 'in_stock'),
              const SizedBox(width: 8),
              _buildFilterBadge('تحت حد الطلب ($lowStockCount)', 'low_stock'),
              const SizedBox(width: 8),
              _buildFilterBadge('نافد ($outOfStockCount)', 'out_of_stock'),
              const Spacer(),

              // Refresh Button
              OutlinedButton.icon(
                onPressed: () => context.read<InventoryCubit>().loadInventoryData(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('تحديث'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.productAdd),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('إضافة صنف'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Table
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty || _stockFilter != 'all'
                            ? 'لا توجد أصناف تطابق نتائج البحث أو الفلتر المحدد'
                            : 'لا توجد منتجات مسجلة في المخزن حالياً',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_searchQuery.isNotEmpty || _stockFilter != 'all')
                        TextButton.icon(
                          onPressed: () => setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                            _stockFilter = 'all';
                          }),
                          icon: const Icon(Icons.filter_alt_off),
                          label: const Text('إعادة تعيين الفلاتر'),
                        ),
                    ],
                  ),
                )
              : Container(
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
                            DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الصنف والباركود', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('التصنيف والنوع', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(
                              label: Row(
                                children: [
                                  Icon(Icons.layers, size: 16, color: AppTheme.primary),
                                  SizedBox(width: 6),
                                  Text(
                                    'رصيد المخزن الفعلي (عدد القطع)',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                                  ),
                                ],
                              ),
                            ),
                            DataColumn(label: Text('الحد الأدنى', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('سعر الشراء (التكلفة)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('سعر البيع', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('إجمالي قيمة الرصيد', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('حالة التوفر', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: filtered.map((p) {
                            final isOutOfStock = p.currentQuantity <= 0;
                            final isLowStock = p.isLowStock && !isOutOfStock;
                            final qtyColor = isOutOfStock
                                ? AppTheme.error
                                : (isLowStock ? Colors.orange.shade800 : AppTheme.success);

                            final totalProductValue = p.currentQuantity * p.costPrice;

                            return DataRow(
                              cells: [
                                // # ID
                                DataCell(
                                  Text(
                                    '${p.id}',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  ),
                                ),

                                // Name & Barcode
                                DataCell(
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          p.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        if (p.barcode != null && p.barcode!.isNotEmpty)
                                          Text(
                                            p.barcode!,
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Category & Type
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(p.categoryName ?? '—', style: const TextStyle(fontSize: 13)),
                                      if (p.productTypeName != null && p.productTypeName!.isNotEmpty)
                                        Text(
                                          p.productTypeName!,
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                        ),
                                    ],
                                  ),
                                ),

                                // Exact Piece Quantity Badge (MAIN HIGHLIGHT)
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: qtyColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: qtyColor.withValues(alpha: 0.35)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: qtyColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${p.currentQuantity.toStringAsFixed(0)} ${p.unit}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: qtyColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Min Quantity
                                DataCell(
                                  Text(
                                    '${p.minQuantity.toStringAsFixed(0)} ${p.unit}',
                                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                  ),
                                ),

                                // Cost Price
                                DataCell(
                                  Text(
                                    CurrencyFormatter.format(p.costPrice),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),

                                // Sell Price
                                DataCell(
                                  Text(
                                    CurrencyFormatter.format(p.sellPrice),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),

                                // Total Value (Quantity * Cost)
                                DataCell(
                                  Text(
                                    CurrencyFormatter.format(totalProductValue),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey.shade800,
                                    ),
                                  ),
                                ),

                                // Status Badge
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: qtyColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isOutOfStock
                                          ? 'نافد بالكامل'
                                          : (isLowStock ? 'تحت حد الطلب' : 'متوفر بالمخزن'),
                                      style: TextStyle(
                                        color: qtyColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                // Actions
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Tooltip(
                                        message: 'إضافة أو زيادة رصيد هذا الصنف يدوياً',
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(6),
                                          onTap: () => _showManualStockDialog(context, product: p),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppTheme.success.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(Icons.add_circle_outline, size: 16, color: AppTheme.success),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Tooltip(
                                        message: 'عرض سجل حركات هذا الصنف في المخزن',
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(6),
                                          onTap: () {
                                            context.read<InventoryCubit>().filterMovementsByProduct(p.id, p.name);
                                            _tabController.animateTo(1);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(Icons.swap_vert, size: 16, color: AppTheme.primary),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Tooltip(
                                        message: 'تعديل الصنف',
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(6),
                                          onTap: () => context.go('/products/${p.id}/edit'),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.textSecondary),
                                          ),
                                        ),
                                      ),
                                      if (p.currentQuantity <= p.minQuantity) ...[
                                        const SizedBox(width: 6),
                                        Tooltip(
                                          message: 'طلب شراء للمخزن',
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(6),
                                            onTap: () => context.go(AppRoutes.purchaseAdd),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Icon(Icons.add_shopping_cart, size: 16, color: Colors.orange.shade800),
                                            ),
                                          ),
                                        ),
                                      ],
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

  Widget _buildFilterBadge(String label, String filterKey) {
    final isSelected = _stockFilter == filterKey;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _stockFilter = filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
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

  // ─── TAB 1: MOVEMENTS TAB (سجل الحركات) ───
  Widget _buildMovementsTab(InventoryLoaded state, DateFormat dateFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter banner if filtered by a specific product
        if (state.filteredProductId != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_alt, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'عرض حركات الصنف: ${state.filteredProductName ?? 'صنف #${state.filteredProductId}'}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => context.read<InventoryCubit>().filterMovementsByProduct(null),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('إلغاء التصفية (عرض كل الحركات)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ),

        // Movements Table
        Expanded(
          child: state.movements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        state.filteredProductId != null
                            ? 'لا توجد حركات مسجلة لهذا الصنف حتى الآن'
                            : 'لا توجد حركات مخزون مسجلة حتى الآن',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (state.filteredProductId != null) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.read<InventoryCubit>().filterMovementsByProduct(null),
                          child: const Text('عرض حركات جميع الأصناف'),
                        ),
                      ],
                    ],
                  ),
                )
              : Container(
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
                            DataColumn(label: Text('الصنف', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('نوع الحركة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الرصيد قبل', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الرصيد بعد', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('السبب / البيان', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: state.movements.map((m) {
                            final isPositive = m.quantity > 0;
                            return DataRow(
                              cells: [
                                DataCell(Text(dateFormat.format(m.createdAt))),
                                DataCell(Text(m.productName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isPositive
                                          ? AppTheme.success.withValues(alpha: 0.12)
                                          : Colors.orange.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      m.typeLabel,
                                      style: TextStyle(
                                        color: isPositive ? AppTheme.success : Colors.orange.shade900,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${isPositive ? '+' : ''}${m.quantity}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isPositive ? AppTheme.success : AppTheme.error,
                                    ),
                                  ),
                                ),
                                DataCell(Text('${m.quantityBefore}')),
                                DataCell(Text('${m.quantityAfter}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text(m.reason ?? m.notes ?? '-')),
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

  // ─── TAB 2: LOW STOCK (النواقص) ───
  Widget _buildLowStockTab(InventoryLoaded state) {
    if (state.lowStockProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: AppTheme.success),
            const SizedBox(height: 16),
            const Text(
              'لا توجد أصناف تحت حد الطلب',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('جميع المنتجات في المخزن متوفرة بكميات آمنة وكافية'),
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
                DataColumn(label: Text('الصنف', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('الباركود', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('الرصيد الفعلي الحالي', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('الحد الأدنى', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('الإجراء', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: state.lowStockProducts.map((p) {
                final isOutOfStock = p.currentQuantity <= 0;
                return DataRow(
                  cells: [
                    DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(p.barcode ?? '-')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isOutOfStock ? AppTheme.error : Colors.orange.shade800).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${p.currentQuantity.toStringAsFixed(0)} ${p.unit}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isOutOfStock ? AppTheme.error : Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text('${p.minQuantity.toStringAsFixed(0)} ${p.unit}')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOutOfStock ? AppTheme.error.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isOutOfStock ? 'نفد من المخزن بالكامل' : 'اقترب من النفاد',
                          style: TextStyle(
                            color: isOutOfStock ? AppTheme.error : Colors.orange.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _showManualStockDialog(context, product: p),
                            icon: const Icon(Icons.add_circle, size: 16),
                            label: const Text('زيادة رصيد يدوي'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton.icon(
                            onPressed: () => context.go(AppRoutes.purchaseAdd),
                            icon: const Icon(Icons.add_shopping_cart, size: 16),
                            label: const Text('طلب شراء'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.swap_vert, size: 18),
                            tooltip: 'سجل حركات الصنف',
                            color: AppTheme.primary,
                            onPressed: () {
                              context.read<InventoryCubit>().filterMovementsByProduct(p.id, p.name);
                              _tabController.animateTo(1);
                            },
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
    );
  }

  // ─── TAB 3: DAMAGES (التوالف والهالك) ───
  Widget _buildDamagesTab(InventoryLoaded state, DateFormat dateFormat) {
    if (state.damages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('لا توجد توالف مسجلة في المخزن'),
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
                DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('الصنف', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('الكمية التالفة', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('سعر التكلفة', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('إجمالي الخسارة', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('سبب التلف', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: state.damages.map((d) {
                return DataRow(
                  cells: [
                    DataCell(Text(dateFormat.format(d.createdAt))),
                    DataCell(Text(d.productName, style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text('${d.quantity}', style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold))),
                    DataCell(Text(CurrencyFormatter.format(d.costPrice))),
                    DataCell(
                      Text(
                        CurrencyFormatter.format(d.totalCost),
                        style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(Text(d.reason)),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // نافذة إضافة وتعديل المخزون يدوياً
  // ─────────────────────────────────────────────
  Future<void> _showManualStockDialog(
    BuildContext context, {
    ProductEntity? product,
    List<ProductEntity> allProducts = const [],
  }) async {
    final invCubit = context.read<InventoryCubit>();
    final prodCubit = context.read<ProductsCubit>();
    final user = context.read<AuthCubit>().currentUser;

    ProductEntity? selectedProduct = product;
    if (selectedProduct == null && allProducts.isNotEmpty) {
      selectedProduct = allProducts.first;
    }

    final qtyController = TextEditingController();
    final reasonController = TextEditingController(text: 'إضافة بضاعة واردة');
    final notesController = TextEditingController();
    int adjustmentMode = 0; // 0 = إضافة (+), 1 = تعيين الرصيد الإجمالي (=), 2 = صرف / إنقاص (-)

    await showDialog(
      context: context,
      builder: (dlgContext) => StatefulBuilder(
        builder: (context, setDlgState) {
          final currentQty = selectedProduct?.currentQuantity ?? 0.0;
          final unit = selectedProduct?.unit ?? 'قطعة';

          double enteredVal = double.tryParse(qtyController.text) ?? 0.0;
          double resultingQty = currentQty;
          if (adjustmentMode == 0) {
            resultingQty = currentQty + enteredVal;
          } else if (adjustmentMode == 1) {
            resultingQty = enteredVal;
          } else if (adjustmentMode == 2) {
            resultingQty = currentQty - enteredVal;
          }

          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory_2_rounded, color: AppTheme.success, size: 22),
                ),
                const SizedBox(width: 10),
                const Text('إضافة أو تعديل رصيد المخزون يدوياً', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Selection
                    if (product == null && allProducts.isNotEmpty) ...[
                      const Text('اختر الصنف المطلوب:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<ProductEntity>(
                        initialValue: selectedProduct,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: allProducts.map((p) => DropdownMenuItem(
                          value: p,
                          child: Text('${p.name} (الرصيد الحالي: ${p.currentQuantity.toStringAsFixed(0)} ${p.unit})'),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDlgState(() {
                              selectedProduct = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ] else if (selectedProduct != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(selectedProduct!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                if (selectedProduct!.barcode != null && selectedProduct!.barcode!.isNotEmpty)
                                  Text('الباركود: ${selectedProduct!.barcode}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'الرصيد الحالي: ${currentQty.toStringAsFixed(0)} $unit',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Mode Selection Segmented
                    const Text('نوع العملية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('إضافة كمية (+)'), icon: Icon(Icons.add, size: 16)),
                        ButtonSegment(value: 1, label: Text('تحديد الرصيد (=)'), icon: Icon(Icons.edit, size: 16)),
                        ButtonSegment(value: 2, label: Text('صرف كمية (-)'), icon: Icon(Icons.remove, size: 16)),
                      ],
                      selected: {adjustmentMode},
                      onSelectionChanged: (set) {
                        setDlgState(() => adjustmentMode = set.first);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Quantity Input
                    Text(
                      adjustmentMode == 0
                          ? 'الكمية المراد إضافتها للمخزن بالقطع:'
                          : adjustmentMode == 1
                              ? 'الرصيد الإجمالي الفعلي الجديد:'
                              : 'الكمية المراد صرفها/خصمها من المخزن:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: qtyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        suffixText: unit,
                        hintText: '0',
                      ),
                      onChanged: (_) => setDlgState(() {}),
                    ),
                    const SizedBox(height: 8),

                    // Quick Chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [1, 5, 10, 20, 50, 100].map((step) {
                        return ActionChip(
                          label: Text('+$step'),
                          onPressed: () {
                            final cur = double.tryParse(qtyController.text) ?? 0.0;
                            qtyController.text = (cur + step).toStringAsFixed(0);
                            setDlgState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Resulting Preview Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: (resultingQty >= 0 ? AppTheme.success : AppTheme.error).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: (resultingQty >= 0 ? AppTheme.success : AppTheme.error).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الرصيد الجديد بعد التعديل:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '${resultingQty.toStringAsFixed(0)} $unit',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: resultingQty >= 0 ? AppTheme.success : AppTheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reason Selector
                    const Text('سبب الإضافة / التعديل:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: reasonController.text,
                      isExpanded: true,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'إضافة بضاعة واردة', child: Text('إضافة بضاعة واردة')),
                        DropdownMenuItem(value: 'تعديل رصيد يدوي', child: Text('تعديل رصيد يدوي')),
                        DropdownMenuItem(value: 'رصيد بضاعة أول المدة', child: Text('رصيد بضاعة أول المدة')),
                        DropdownMenuItem(value: 'مشتريات غير مسجلة بفاتورة', child: Text('مشتريات غير مسجلة بفاتورة')),
                        DropdownMenuItem(value: 'تسوية سريعة', child: Text('تسوية سريعة')),
                        DropdownMenuItem(value: 'صرف عينات أو هدايا', child: Text('صرف عينات أو هدايا')),
                        DropdownMenuItem(value: 'أخرى', child: Text('أخرى')),
                      ],
                      onChanged: (v) {
                        if (v != null) setDlgState(() => reasonController.text = v);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Notes
                    const Text('ملاحظات إضافية (اختياري):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'أي ملاحظات تخص هذه الحركة...'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dlgContext), child: const Text('إلغاء')),
              ElevatedButton.icon(
                onPressed: () async {
                  if (selectedProduct == null) return;
                  final entered = double.tryParse(qtyController.text);
                  if (entered == null || entered <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى إدخال كمية صحيحة أكبر من صفر'), backgroundColor: AppTheme.error),
                    );
                    return;
                  }

                  double delta = 0.0;
                  if (adjustmentMode == 0) {
                    delta = entered;
                  } else if (adjustmentMode == 1) {
                    delta = entered - currentQty;
                  } else if (adjustmentMode == 2) {
                    delta = -entered;
                  }

                  if (delta == 0) {
                    Navigator.pop(dlgContext);
                    return;
                  }

                  final success = await invCubit.manualStockAdjustment(
                    productId: selectedProduct!.id,
                    quantityDelta: delta,
                    reason: reasonController.text.trim(),
                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    userId: user?.id,
                  );

                  if (context.mounted) {
                    Navigator.pop(dlgContext);
                    if (success) {
                      await prodCubit.loadProducts();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم تحديث رصيد الصنف "${selectedProduct!.name}" بنجاح إلى ${resultingQty.toStringAsFixed(0)} $unit'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('حدث خطأ أثناء تعديل المخزون'), backgroundColor: AppTheme.error),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('حفظ وتحديث الرصيد'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, foregroundColor: Colors.white),
              ),
            ],
          );
        },
      ),
    );
  }
}
