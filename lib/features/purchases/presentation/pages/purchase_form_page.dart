import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../suppliers/presentation/cubit/suppliers_cubit.dart';
import '../../../suppliers/domain/entities/supplier_entity.dart';
import '../../../products/presentation/cubit/products_cubit.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../cubit/purchases_cubit.dart';
import '../../domain/entities/purchase_entity.dart';

class PurchaseFormItem {
  ProductEntity? product;
  double quantity;
  double unitCost;

  PurchaseFormItem({
    this.product,
    this.quantity = 1,
    this.unitCost = 0.0,
  });

  double get total => quantity * unitCost;
}

class PurchaseFormPage extends StatefulWidget {
  const PurchaseFormPage({super.key});

  @override
  State<PurchaseFormPage> createState() => _PurchaseFormPageState();
}

class _PurchaseFormPageState extends State<PurchaseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _invNumberController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _paidController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  SupplierEntity? _selectedSupplier;
  String _paymentType = 'cash';
  bool _isLoading = false;

  final List<PurchaseFormItem> _items = [PurchaseFormItem()];

  @override
  void initState() {
    super.initState();
    context.read<SuppliersCubit>().loadSuppliers();
    context.read<ProductsCubit>().loadProducts();
  }

  @override
  void dispose() {
    _invNumberController.dispose();
    _discountController.dispose();
    _paidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get subtotal => _items.fold(0.0, (sum, i) => sum + i.total);
  double get discount => double.tryParse(_discountController.text) ?? 0.0;
  double get total => (subtotal - discount) > 0 ? (subtotal - discount) : 0.0;
  double get paid => _paymentType == 'cash' ? total : (double.tryParse(_paidController.text) ?? 0.0);
  double get remaining => (total - paid) > 0 ? (total - paid) : 0.0;

  void _addItem() {
    setState(() {
      _items.add(PurchaseFormItem());
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final validItems = _items.where((i) => i.product != null && i.quantity > 0 && i.unitCost >= 0).toList();
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إضافة صنف واحد على الأقل بكمية وتكلفة صحيحة')),
      );
      return;
    }

    if (_paymentType == 'credit' && _selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن تسجيل فاتورة شراء آجلة بدون تحديد المورد')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final purchase = PurchaseEntity(
      id: 0,
      invoiceNumber: _invNumberController.text.trim(),
      supplierId: _selectedSupplier?.id,
      subtotal: subtotal,
      discountAmount: discount,
      totalAmount: total,
      paidAmount: paid,
      remainingAmount: remaining,
      paymentType: _paymentType,
      status: 'completed',
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final purchaseItems = validItems
        .map((i) => PurchaseItemEntity(
              id: 0,
              purchaseId: 0,
              productId: i.product!.id,
              productName: i.product!.name,
              quantity: i.quantity,
              unitCost: i.unitCost,
              totalCost: i.total,
            ))
        .toList();

    final resultId = await context.read<PurchasesCubit>().createPurchase(
          purchase: purchase,
          items: purchaseItems,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (resultId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تسجيل فاتورة الشراء وتحديث أرصدة المخزون والتكلفة بنجاح'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.go(AppRoutes.purchases);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('تسجيل فاتورة شراء بضاعة واردة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.purchases),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Supplier & Invoice Header Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppTheme.border),
                    ),
                    color: AppTheme.cardBackground,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue.withValues(alpha: 0.12),
                                foregroundColor: Colors.blue.shade900,
                                radius: 24,
                                child: const Icon(Icons.receipt, size: 28),
                              ),
                              const SizedBox(width: 16),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'بيانات المورد وفاتورة الشراء',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  SizedBox(height: 4),
                                  Text('حدد المورد ورقم الفاتورة الدفترية وطريقة الدفع'),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          Row(
                            children: [
                              // Supplier Selector
                              Expanded(
                                flex: 2,
                                child: BlocBuilder<SuppliersCubit, SuppliersState>(
                                  builder: (context, state) {
                                    List<SupplierEntity> suppliers = [];
                                    if (state is SuppliersLoaded) {
                                      suppliers = state.suppliers;
                                    }

                                    return DropdownButtonFormField<SupplierEntity?>(
                                      initialValue: _selectedSupplier,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'المورد',
                                        prefixIcon: Icon(Icons.business_outlined),
                                        border: OutlineInputBorder(),
                                      ),
                                      items: [
                                        const DropdownMenuItem<SupplierEntity?>(
                                          value: null,
                                          child: Text('مورد نقدي عام'),
                                        ),
                                        ...suppliers.map((s) => DropdownMenuItem(
                                              value: s,
                                              child: Text('${s.name} ${s.company != null ? "(${s.company})" : ""}'),
                                            )),
                                      ],
                                      onChanged: (val) {
                                        setState(() => _selectedSupplier = val);
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Invoice Number
                              Expanded(
                                child: TextFormField(
                                  controller: _invNumberController,
                                  decoration: const InputDecoration(
                                    labelText: 'رقم الفاتورة (اختياري)',
                                    hintText: 'يترك فارغاً للتوليد التلقائي',
                                    prefixIcon: Icon(Icons.numbers),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Items Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppTheme.border),
                    ),
                    color: AppTheme.cardBackground,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'بنود وأصناف الفاتورة',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              ElevatedButton.icon(
                                onPressed: _addItem,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('إضافة بند جديد'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 28),

                          BlocBuilder<ProductsCubit, ProductsState>(
                            builder: (context, prodState) {
                              List<ProductEntity> products = [];
                              if (prodState is ProductsLoaded) {
                                products = prodState.products;
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _items.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final item = _items[index];

                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Product Dropdown
                                      Expanded(
                                        flex: 4,
                                        child: DropdownButtonFormField<ProductEntity>(
                                          initialValue: item.product,
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            labelText: 'الصنف ${index + 1} *',
                                            border: const OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                          items: products.map((p) {
                                            return DropdownMenuItem(
                                              value: p,
                                              child: Text('${p.name} (التكلفة السابقة: ${p.costPrice} ج)'),
                                            );
                                          }).toList(),
                                          onChanged: (p) {
                                            setState(() {
                                              item.product = p;
                                              if (p != null && item.unitCost == 0.0) {
                                                item.unitCost = p.costPrice;
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Quantity
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          initialValue: item.quantity.toString(),
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: InputDecoration(
                                            labelText: 'الكمية',
                                            suffixText: item.product?.unit ?? 'قطعة',
                                            border: const OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                          onChanged: (val) {
                                            setState(() {
                                              item.quantity = double.tryParse(val) ?? 0.0;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Unit Cost
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          initialValue: item.unitCost.toString(),
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(
                                            labelText: 'سعر الشراء (ج)',
                                            border: OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                          onChanged: (val) {
                                            setState(() {
                                              item.unitCost = double.tryParse(val) ?? 0.0;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Item Total
                                      SizedBox(
                                        width: 110,
                                        child: Text(
                                          '${item.total.toStringAsFixed(2)} ج',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),

                                      // Remove Item
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                                        onPressed: () => _removeItem(index),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Financial Breakdown & Payment Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppTheme.border),
                    ),
                    color: AppTheme.cardBackground,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Notes
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _notesController,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    labelText: 'ملاحظات الفاتورة',
                                    border: OutlineInputBorder(),
                                    alignLabelWithHint: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),

                              // Financial Totals
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('المجموع الفرعي:'),
                                        Text('${subtotal.toStringAsFixed(2)} ج', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Text('الخصم (ج):'),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: TextField(
                                            controller: _discountController,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('الإجمالي المستحق:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text(
                                          '${total.toStringAsFixed(2)} ج',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Payment Method
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ChoiceChip(
                                            label: const Center(child: Text('سداد نقدي')),
                                            selected: _paymentType == 'cash',
                                            onSelected: (_) => setState(() => _paymentType = 'cash'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ChoiceChip(
                                            label: const Center(child: Text('شراء آجل')),
                                            selected: _paymentType == 'credit',
                                            onSelected: (_) => setState(() => _paymentType = 'credit'),
                                          ),
                                        ),
                                      ],
                                    ),

                                    if (_paymentType == 'credit') ...[
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Text('المدفوع نقداً:'),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: TextField(
                                              controller: _paidController,
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                                              onChanged: (_) => setState(() {}),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('المتبقي للمورد:', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
                                          Text(
                                            '${remaining.toStringAsFixed(2)} ج',
                                            style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 36),

                          // Submit Action
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => context.go(AppRoutes.purchases),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                ),
                                child: const Text('إلغاء'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: _isLoading ? null : _submit,
                                icon: const Icon(Icons.check),
                                label: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text('حفظ فاتورة الشراء وتحديث الأرصدة'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
