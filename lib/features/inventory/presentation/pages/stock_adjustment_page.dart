import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../products/presentation/cubit/products_cubit.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../cubit/inventory_cubit.dart';

class StockAdjustmentPage extends StatefulWidget {
  const StockAdjustmentPage({super.key});

  @override
  State<StockAdjustmentPage> createState() => _StockAdjustmentPageState();
}

class _StockAdjustmentPageState extends State<StockAdjustmentPage> {
  final TextEditingController _notesController = TextEditingController();
  final Map<int, TextEditingController> _controllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    context.read<ProductsCubit>().loadProducts();
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getControllerFor(ProductEntity product) {
    if (!_controllers.containsKey(product.id)) {
      _controllers[product.id] = TextEditingController(text: product.currentQuantity.toString());
    }
    return _controllers[product.id]!;
  }

  Future<void> _submitAdjustment(List<ProductEntity> products) async {
    final List<Map<String, dynamic>> items = [];

    for (final p in products) {
      final ctrl = _getControllerFor(p);
      final actualQty = double.tryParse(ctrl.text.trim()) ?? p.currentQuantity;
      final diff = actualQty - p.currentQuantity;

      // Only include items that have differences or all items
      items.add({
        'product_id': p.id,
        'product_name': p.name,
        'system_quantity': p.currentQuantity,
        'actual_quantity': actualQty,
        'difference': diff,
      });
    }

    setState(() => _isSaving = true);

    final cubit = context.read<InventoryCubit>();
    final adjId = await cubit.createAdjustment(
      notes: _notesController.text.trim().isEmpty ? 'جرد مخزون دوري' : _notesController.text.trim(),
      items: items,
    );

    if (adjId) {
      // Prompt user whether to approve immediately
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('تم حفظ مسودة الجرد بنجاح'),
            content: const Text('هل ترغب في اعتماد وتطبيق فروقات الجرد على المخزون الآن؟'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go(AppRoutes.inventory);
                },
                child: const Text('لاحقاً (حفظ كمسودة)'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  // Load latest adjustments to get the id or we can approve
                  final latestState = context.read<InventoryCubit>().state;
                  if (latestState is InventoryLoaded && latestState.adjustments.isNotEmpty) {
                    await context.read<InventoryCubit>().approveAdjustment(latestState.adjustments.first.id);
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم اعتماد الجرد وتحديث أرصدة الأصناف بالمخزن بنجاح'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                    context.go(AppRoutes.inventory);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                child: const Text('نعم، اعتماد وتطبيق فوراً'),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء حفظ الجرد')),
        );
      }
    }

    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('محضر جرد المخزون الفعلي وتسوية الأرصدة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.inventory),
        ),
      ),
      body: BlocBuilder<ProductsCubit, ProductsState>(
        builder: (context, state) {
          if (state is ProductsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProductsLoaded) {
            final products = state.products;

            if (products.isEmpty) {
              return const Center(child: Text('لا توجد أصناف في قاعدة البيانات لإجراء الجرد عليها'));
            }

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Top Info & Notes Card
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
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'ملاحظات / سبب الجرد',
                              hintText: 'مثال: جرد نهاية الشهر، جرد سنوي، تسوية دورية...',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.description_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : () => _submitAdjustment(products),
                          icon: const Icon(Icons.save),
                          label: _isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('حفظ محضر الجرد'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stock Table
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
                                DataColumn(label: Text('اسم الصنف', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('الباركود', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('الرصيد الدفتري (الحالي)', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('العد الفعلي بالمخزن', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('الفرق (عجز / زيادة)', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: products.asMap().entries.map((entry) {
                                final index = entry.key + 1;
                                final p = entry.value;
                                final ctrl = _getControllerFor(p);
                                final actualQty = double.tryParse(ctrl.text) ?? p.currentQuantity;
                                final diff = actualQty - p.currentQuantity;

                                return DataRow(
                                  cells: [
                                    DataCell(Text('$index')),
                                    DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(Text(p.barcode ?? '-')),
                                    DataCell(Text('${p.currentQuantity} ${p.unit}')),
                                    DataCell(
                                      SizedBox(
                                        width: 120,
                                        child: TextField(
                                          controller: ctrl,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          textAlign: TextAlign.center,
                                          onChanged: (val) {
                                            setState(() {});
                                          },
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: diff == 0
                                              ? AppTheme.border.withValues(alpha: 0.5)
                                              : (diff > 0
                                                  ? AppTheme.success.withValues(alpha: 0.12)
                                                  : AppTheme.error.withValues(alpha: 0.12)),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          diff == 0 ? 'مطابق (0)' : (diff > 0 ? 'زيادة (+$diff)' : 'عجز ($diff)'),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: diff == 0
                                                ? AppTheme.textSecondary
                                                : (diff > 0 ? AppTheme.success : AppTheme.error),
                                          ),
                                        ),
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
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}
