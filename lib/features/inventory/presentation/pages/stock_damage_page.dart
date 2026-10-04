import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../products/presentation/cubit/products_cubit.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../cubit/inventory_cubit.dart';

class StockDamagePage extends StatefulWidget {
  const StockDamagePage({super.key});

  @override
  State<StockDamagePage> createState() => _StockDamagePageState();
}

class _StockDamagePageState extends State<StockDamagePage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  ProductEntity? _selectedProduct;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    context.read<ProductsCubit>().loadProducts();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedProduct == null) {
      if (_selectedProduct == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار الصنف التالف أولاً')),
        );
      }
      return;
    }

    final qty = double.tryParse(_quantityController.text) ?? 0.0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال كمية صحيحة أكبر من الصفر')),
      );
      return;
    }

    if (qty > _selectedProduct!.currentQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الكمية التالفة ($qty) أكبر من الرصيد المتوفر بالمخزن (${_selectedProduct!.currentQuantity})')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await context.read<InventoryCubit>().recordDamage(
          productId: _selectedProduct!.id,
          quantity: qty,
          reason: _reasonController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تسجيل الهالك وخصم الكمية من المخزون بنجاح'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.go(AppRoutes.inventory);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('تسجيل بضاعة تالفة / هالك'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.inventory),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.border),
              ),
              color: AppTheme.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.error.withValues(alpha: 0.12),
                            foregroundColor: AppTheme.error,
                            radius: 24,
                            child: const Icon(Icons.delete_sweep, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تسجيل تالف أو منتهي الصلاحية',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Text('سيتم خصم الكمية تلقائياً من رصيد الصنف وتسجيل قيمة التكلفة كخسارة هالك'),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 36),

                      // Select Product
                      BlocBuilder<ProductsCubit, ProductsState>(
                        builder: (context, state) {
                          List<ProductEntity> products = [];
                          if (state is ProductsLoaded) {
                            products = state.products;
                          }

                          return DropdownButtonFormField<ProductEntity>(
                            initialValue: _selectedProduct,
                            decoration: const InputDecoration(
                              labelText: 'اختر الصنف *',
                              prefixIcon: Icon(Icons.category_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: products.map((p) {
                              return DropdownMenuItem(
                                value: p,
                                child: Text('${p.name} (المتوفر: ${p.currentQuantity} ${p.unit})'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedProduct = val;
                              });
                            },
                            validator: (val) => val == null ? 'الرجاء اختيار الصنف' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Current Stock & Cost Info Box
                      if (_selectedProduct != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text('الرصيد المتوفر بالمخزن', style: TextStyle(color: AppTheme.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_selectedProduct!.currentQuantity} ${_selectedProduct!.unit}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text('سعر التكلفة للوحدة', style: TextStyle(color: AppTheme.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_selectedProduct!.costPrice.toStringAsFixed(2)} ج',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Damaged Quantity
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'الكمية التالفة *',
                          suffixText: _selectedProduct?.unit ?? 'قطعة',
                          prefixIcon: const Icon(Icons.exposure_minus_1),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'الكمية مطلوبة';
                          if (double.tryParse(val) == null) return 'أدخل رقم صحيح';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Reason
                      TextFormField(
                        controller: _reasonController,
                        decoration: const InputDecoration(
                          labelText: 'سبب التلف أو الهالك *',
                          hintText: 'مثال: كسر أثناء النقل، انتهاء صلاحية، عيب صناعة...',
                          prefixIcon: Icon(Icons.help_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'سبب التلف مطلوب';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات إضافية',
                          prefixIcon: Icon(Icons.notes),
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Submit Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => context.go(AppRoutes.inventory),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            ),
                            child: const Text('إلغاء'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _submit,
                            icon: const Icon(Icons.check),
                            label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('تأكيد خصم الهالك'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
