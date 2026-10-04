import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../cubit/products_cubit.dart';
import '../../domain/entities/product_entity.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/domain/entities/category_entity.dart';

class ProductFormPage extends StatelessWidget {
  final int? productId;
  const ProductFormPage({super.key, this.productId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) => sl<ProductsCubit>()..loadProducts()),
        BlocProvider(
            create: (_) => sl<CategoriesCubit>()..loadCategories()),
      ],
      child: _ProductFormView(productId: productId),
    );
  }
}

class _ProductFormView extends StatefulWidget {
  final int? productId;
  const _ProductFormView({this.productId});

  @override
  State<_ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends State<_ProductFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _unitCtrl = TextEditingController(text: 'قطعة');
  final _minQtyCtrl = TextEditingController(text: '0');
  final _costPriceCtrl = TextEditingController(text: '0');
  final _sellPriceCtrl = TextEditingController(text: '0');
  final _groupPriceCtrl = TextEditingController(text: '0');
  final _groupQtyCtrl = TextEditingController(text: '1');
  final _currentQtyCtrl = TextEditingController(text: '0');

  int? _selectedCategoryId;
  int? _selectedTypeId;
  String _status = 'active';
  bool _isLoading = false;
  bool _isEditing = false;
  ProductEntity? _originalProduct;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _isEditing = true;
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    final cubit = context.read<ProductsCubit>();
    final product = await cubit.getById(widget.productId!);
    if (product != null && mounted) {
      setState(() {
        _originalProduct = product;
        _nameCtrl.text = product.name;
        _barcodeCtrl.text = product.barcode ?? '';
        _descCtrl.text = product.description ?? '';
        _unitCtrl.text = product.unit;
        _minQtyCtrl.text = product.minQuantity.toString();
        _costPriceCtrl.text = product.costPrice.toString();
        _sellPriceCtrl.text = product.sellPrice.toString();
        _groupPriceCtrl.text = product.groupPrice.toString();
        _groupQtyCtrl.text = product.groupQuantity.toString();
        _currentQtyCtrl.text = product.currentQuantity.toString();
        _selectedCategoryId = product.categoryId;
        _selectedTypeId = product.productTypeId;
        _status = product.status;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _descCtrl.dispose();
    _unitCtrl.dispose();
    _minQtyCtrl.dispose();
    _costPriceCtrl.dispose();
    _sellPriceCtrl.dispose();
    _groupPriceCtrl.dispose();
    _groupQtyCtrl.dispose();
    _currentQtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    final product = ProductEntity(
      id: widget.productId ?? 0,
      name: _nameCtrl.text.trim(),
      barcode: _barcodeCtrl.text.trim().isEmpty
          ? null
          : _barcodeCtrl.text.trim(),
      categoryId: _selectedCategoryId,
      productTypeId: _selectedTypeId,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      unit: _unitCtrl.text.trim(),
      currentQuantity: double.tryParse(_currentQtyCtrl.text) ?? 0,
      minQuantity: double.tryParse(_minQtyCtrl.text) ?? 0,
      costPrice: double.tryParse(_costPriceCtrl.text) ?? 0,
      sellPrice: double.tryParse(_sellPriceCtrl.text) ?? 0,
      groupPrice: double.tryParse(_groupPriceCtrl.text) ?? 0,
      groupQuantity: double.tryParse(_groupQtyCtrl.text) ?? 1,
      weightedAvgCost: double.tryParse(_costPriceCtrl.text) ?? 0,
      status: _status,
      createdAt: _originalProduct?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await context.read<ProductsCubit>().saveProduct(product);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEditing ? 'تم تعديل المنتج' : 'تم إضافة المنتج'),
        backgroundColor: AppTheme.success,
      ));
      context.go('/products');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('حدث خطأ أثناء حفظ المنتج، يرجى المحاولة مرة أخرى'),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  void _showQuickAddCategory(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController();
    final cubit = context.read<CategoriesCubit>();

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('إضافة تصنيف جديد'),
        content: SizedBox(
          width: 340,
          child: Form(
            key: formKey,
            child: TextFormField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'اسم التصنيف *',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم التصنيف' : null,
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final name = ctrl.text.trim();
              final id = await cubit.createCategoryAndReturnId(name, null);
              if (id != null && dlgCtx.mounted) {
                Navigator.pop(dlgCtx);
                if (mounted) {
                  setState(() {
                    _selectedCategoryId = id;
                    _selectedTypeId = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تمت إضافة التصنيف "$name" وتحديده بنجاح'), backgroundColor: AppTheme.success),
                  );
                }
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showQuickAddType(BuildContext context) {
    final categoriesState = context.read<CategoriesCubit>().state;
    final categories = categoriesState is CategoriesLoaded ? categoriesState.categories : <CategoryEntity>[];
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة تصنيف أولاً قبل إضافة الأنواع'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController();
    final cubit = context.read<CategoriesCubit>();
    int targetCatId = (_selectedCategoryId != null && categories.any((c) => c.id == _selectedCategoryId))
        ? _selectedCategoryId!
        : categories.first.id;

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('إضافة نوع جديد'),
          content: SizedBox(
            width: 340,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    key: ValueKey(targetCatId),
                    initialValue: targetCatId,
                    decoration: const InputDecoration(labelText: 'التصنيف *', prefixIcon: Icon(Icons.category_outlined)),
                    items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => targetCatId = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: ctrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'اسم النوع *',
                      hintText: 'مثال: شاشات سمارت، مياه غازية...',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم النوع' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final name = ctrl.text.trim();
                final id = await cubit.createTypeAndReturnId(targetCatId, name, null);
                if (id != null && dlgCtx.mounted) {
                  Navigator.pop(dlgCtx);
                  if (mounted) {
                    setState(() {
                      _selectedCategoryId = targetCatId;
                      _selectedTypeId = id;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تمت إضافة النوع "$name" وتحديده بنجاح'), backgroundColor: AppTheme.success),
                    );
                  }
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          Row(
            children: [
              IconButton(
                onPressed: () => context.go('/products'),
                icon: const Icon(Icons.arrow_forward),
                tooltip: 'رجوع',
              ),
              const SizedBox(width: 8),
              Text(
                _isEditing ? 'تعديل المنتج' : 'إضافة منتج جديد',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Form(
              key: _formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العمود الأيسر (المعلومات الأساسية)
                  Expanded(
                    flex: 3,
                    child: _buildMainInfo(),
                  ),
                  const SizedBox(width: 20),
                  // العمود الأيمن (التسعير والمخزون)
                  Expanded(
                    flex: 2,
                    child: _buildPricingInfo(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // أزرار الحفظ
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildMainInfo() {
    return _FormCard(
      title: 'المعلومات الأساسية',
      children: [
        _buildField(
          label: 'اسم المنتج *',
          controller: _nameCtrl,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'يرجى إدخال اسم المنتج' : null,
        ),
        const SizedBox(height: 16),
        _buildField(
          label: 'الباركود',
          controller: _barcodeCtrl,
          hint: 'أدخل الباركود أو امسح باسكانر',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: BlocBuilder<CategoriesCubit, CategoriesState>(
                      builder: (context, state) {
                        final categories = state is CategoriesLoaded
                            ? state.categories
                            : <dynamic>[];
                        final validCatId = categories.any((c) => c.id == _selectedCategoryId)
                            ? _selectedCategoryId
                            : null;
                        return DropdownButtonFormField<int?>(
                          key: ValueKey(validCatId),
                          initialValue: validCatId,
                          decoration: const InputDecoration(labelText: 'التصنيف'),
                          items: [
                            const DropdownMenuItem<int?>(
                                value: null, child: Text('-- بدون تصنيف --')),
                            ...categories.map((c) => DropdownMenuItem<int?>(
                                  value: c.id,
                                  child: Text(c.name),
                                )),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _selectedCategoryId = v;
                              _selectedTypeId = null;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 22),
                    tooltip: 'إضافة تصنيف جديد',
                    onPressed: () => _showQuickAddCategory(context),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: BlocBuilder<CategoriesCubit, CategoriesState>(
                      builder: (context, state) {
                        final types = state is CategoriesLoaded
                            ? state.types
                                .where((t) =>
                                    _selectedCategoryId == null ||
                                    t.categoryId == _selectedCategoryId)
                                .toList()
                            : <dynamic>[];
                        final validTypeId = types.any((t) => t.id == _selectedTypeId)
                            ? _selectedTypeId
                            : null;
                        return DropdownButtonFormField<int?>(
                          key: ValueKey(validTypeId),
                          initialValue: validTypeId,
                          decoration: const InputDecoration(labelText: 'النوع'),
                          items: [
                            const DropdownMenuItem<int?>(
                                value: null, child: Text('-- بدون نوع --')),
                            ...types.map((t) => DropdownMenuItem<int?>(
                                  value: t.id,
                                  child: Text(t.name),
                                )),
                          ],
                          onChanged: (v) => setState(() => _selectedTypeId = v),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 22),
                    tooltip: 'إضافة نوع جديد',
                    onPressed: () => _showQuickAddType(context),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildField(
                label: 'وحدة القياس',
                controller: _unitCtrl,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey(_status),
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'الحالة'),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('نشط')),
                  DropdownMenuItem(value: 'inactive', child: Text('غير نشط')),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'active'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildField(
          label: 'الوصف',
          controller: _descCtrl,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildPricingInfo() {
    return Column(
      children: [
        _FormCard(
          title: 'التسعير',
          children: [
            _buildField(
              label: 'سعر الشراء (ج) *',
              controller: _costPriceCtrl,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'يرجى إدخال سعر الشراء';
                if (double.tryParse(v) == null) {
                  return 'يرجى إدخال رقم صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildField(
              label: 'سعر بيع القطعة (ج) *',
              controller: _sellPriceCtrl,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'يرجى إدخال سعر البيع';
                if (double.tryParse(v) == null) {
                  return 'يرجى إدخال رقم صحيح';
                }
                return null;
              },
            ),
            const Divider(height: 24),
            const Text(
              'سعر المجموعة',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: 'عدد القطع في المجموعة',
                    controller: _groupQtyCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    label: 'سعر المجموعة (ج)',
                    controller: _groupPriceCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _FormCard(
          title: 'المخزون',
          children: [
            _buildField(
              label: _isEditing ? 'الكمية الحالية' : 'الكمية الابتدائية',
              controller: _currentQtyCtrl,
              keyboardType: TextInputType.number,
              enabled: !_isEditing,
              hint: _isEditing
                  ? 'لا يمكن تعديل الكمية مباشرة'
                  : null,
            ),
            const SizedBox(height: 12),
            _buildField(
              label: 'الحد الأدنى للمخزون',
              controller: _minQtyCtrl,
              keyboardType: TextInputType.number,
              hint: 'سيظهر تنبيه عند الوصول لهذا الحد',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => context.go('/products'),
          child: const Text('إلغاء'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(_isEditing ? 'حفظ التعديلات' : 'إضافة المنتج'),
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: !enabled,
        fillColor: enabled ? null : AppTheme.surfaceVariant,
      ),
      validator: validator,
    );
  }
}

class _FormCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FormCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
