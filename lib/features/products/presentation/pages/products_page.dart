import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/di/injection_container.dart';
import '../cubit/products_cubit.dart';
import '../../domain/entities/product_entity.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProductsCubit>()..loadProducts(),
      child: const _ProductsView(),
    );
  }
}

class _ProductsView extends StatefulWidget {
  const _ProductsView();

  @override
  State<_ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<_ProductsView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildToolbar(context),
          const SizedBox(height: 16),
          Expanded(child: _buildProductsList()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المنتجات',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            Text(
              'إدارة قائمة المنتجات والمخزون',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => context.go(AppRoutes.productAdd),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('إضافة منتج'),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'بحث بالاسم أو الباركود...',
              prefixIcon: Icon(Icons.search_outlined, size: 20),
            ),
            onChanged: (v) {
              setState(() => _searchQuery = v);
              Future.delayed(const Duration(milliseconds: 400), () {
                if (_searchQuery == v && mounted) {
                  context.read<ProductsCubit>().loadProducts(search: v);
                }
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () => context.go(AppRoutes.inventory),
          icon: const Icon(Icons.inventory_2_outlined, size: 18),
          label: const Text('المخزون'),
        ),
      ],
    );
  }

  Widget _buildProductsList() {
    return BlocBuilder<ProductsCubit, ProductsState>(
      builder: (context, state) {
        if (state is ProductsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ProductsError) {
          return _buildError(context, state.message);
        }
        if (state is ProductsLoaded) {
          if (state.products.isEmpty) {
            return _buildEmpty(context);
          }
          return _buildTable(context, state.products);
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildTable(BuildContext context, List<ProductEntity> products) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          // رأس الجدول
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border)),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(AppTheme.radiusMd),
                topLeft: Radius.circular(AppTheme.radiusMd),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(width: 40, child: Text('#', style: _headerStyle)),
                Expanded(flex: 3, child: Text('المنتج', style: _headerStyle)),
                Expanded(flex: 2, child: Text('التصنيف', style: _headerStyle)),
                Expanded(child: Text('الكمية', style: _headerStyle)),
                Expanded(child: Text('سعر الشراء', style: _headerStyle)),
                Expanded(child: Text('سعر البيع', style: _headerStyle)),
                Expanded(child: Text('الحالة', style: _headerStyle)),
                SizedBox(width: 80, child: Text('', style: _headerStyle)),
              ],
            ),
          ),
          // صفوف البيانات
          Expanded(
            child: ListView.separated(
              itemCount: products.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppTheme.borderLight),
              itemBuilder: (context, i) =>
                  _ProductRow(product: products[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 56, color: AppTheme.textHint),
          const SizedBox(height: 16),
          const Text(
            'لا توجد منتجات حالياً',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'ابدأ بإضافة منتجاتك',
            style: TextStyle(fontSize: 13, color: AppTheme.textHint),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go(AppRoutes.productAdd),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('إضافة منتج'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () =>
                context.read<ProductsCubit>().loadProducts(),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  static const TextStyle _headerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppTheme.textSecondary,
  );
}

class _ProductRow extends StatefulWidget {
  final ProductEntity product;
  const _ProductRow({required this.product});

  @override
  State<_ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends State<_ProductRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _isHovered ? AppTheme.surfaceVariant : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                '${p.id}',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textHint),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (p.barcode != null)
                    Text(
                      p.barcode!,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textHint),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                p.categoryName ?? '—',
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: _buildQuantityBadge(p),
            ),
            Expanded(
              child: Text(
                CurrencyFormatter.format(p.costPrice),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Expanded(
              child: Text(
                CurrencyFormatter.format(p.sellPrice),
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: _buildStatusBadge(p.status),
            ),
            SizedBox(
              width: 80,
              child: _isHovered
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionButton(
                          icon: Icons.edit_outlined,
                          tooltip: 'تعديل',
                          onTap: () => context.go(
                              '/products/${p.id}/edit'),
                        ),
                        const SizedBox(width: 4),
                        _ActionButton(
                          icon: Icons.delete_outline,
                          tooltip: 'حذف',
                          color: AppTheme.error,
                          onTap: () => _confirmDelete(context),
                        ),
                      ],
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityBadge(ProductEntity p) {
    Color color;
    if (p.isOutOfStock) {
      color = AppTheme.error;
    } else if (p.isLowStock) {
      color = AppTheme.warning;
    } else {
      color = AppTheme.success;
    }

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '${p.currentQuantity.toStringAsFixed(0)} ${p.unit}',
          style: TextStyle(
              fontSize: 13, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isActive ? AppTheme.success : AppTheme.textHint)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'نشط' : 'غير نشط',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isActive ? AppTheme.success : AppTheme.textHint,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<ProductsCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: Text('هل تريد حذف "${widget.product.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dlgCtx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await cubit.deleteProduct(widget.product.id);
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon,
              size: 17,
              color: color ?? AppTheme.textSecondary),
        ),
      ),
    );
  }
}
