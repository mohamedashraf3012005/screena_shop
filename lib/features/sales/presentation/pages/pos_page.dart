import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/pdf_invoice_helper.dart';
import '../../../products/presentation/cubit/products_cubit.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../customers/presentation/cubit/customers_cubit.dart';
import '../../../customers/domain/entities/customer_entity.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/domain/entities/settings_entity.dart';
import '../cubit/sales_cubit.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  final TextEditingController _barcodeSearchController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();
  final TextEditingController _paidController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  int? _selectedCategoryId;
  String _productSearchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<SalesCubit>().initPos();
    context.read<ProductsCubit>().loadProducts();
    context.read<CategoriesCubit>().loadCategories();
    context.read<CustomersCubit>().loadCustomers();

    // Auto-focus barcode scanner input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _barcodeSearchController.dispose();
    _barcodeFocusNode.dispose();
    _paidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Called on every char — used for live search while typing
  void _onBarcodeFieldChanged(String val) {
    setState(() {
      _productSearchQuery = val.trim();
    });
  }


  void _handleBarcodeSubmit(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    final salesCubit = context.read<SalesCubit>();
    final added = await salesCubit.addByBarcode(trimmed);

    if (mounted) {
      if (added) {
        // Product found and added via barcode — clear search
        setState(() => _productSearchQuery = '');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة المنتج بالباركود'),
            duration: Duration(milliseconds: 800),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        // Not a barcode match — use as text search
        setState(() => _productSearchQuery = trimmed);
      }
    }

    _barcodeSearchController.clear();
    _barcodeFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // ─── LEFT: Products Catalog & Search ───
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Top Search and Barcode Bar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _barcodeSearchController,
                            focusNode: _barcodeFocusNode,
                            onSubmitted: _handleBarcodeSubmit,
                            onChanged: _onBarcodeFieldChanged,
                            decoration: InputDecoration(
                              hintText: 'امسح الباركود أو ابحث باسم الصنف...',
                              prefixIcon: const Icon(Icons.qr_code_scanner, color: AppTheme.primary),
                              suffixIcon: _barcodeSearchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _barcodeSearchController.clear();
                                        setState(() => _productSearchQuery = '');
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
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _handleBarcodeSubmit(_barcodeSearchController.text),
                          icon: const Icon(Icons.add),
                          label: const Text('إدخال'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Categories Filter Chips
                  BlocBuilder<CategoriesCubit, CategoriesState>(
                    builder: (context, catState) {
                      if (catState is CategoriesLoaded) {
                        return SizedBox(
                          height: 44,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: ChoiceChip(
                                  label: const Text('الكل'),
                                  selected: _selectedCategoryId == null,
                                  onSelected: (_) {
                                    setState(() => _selectedCategoryId = null);
                                  },
                                ),
                              ),
                              ...catState.categories.map((cat) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: ChoiceChip(
                                    label: Text(cat.name),
                                    selected: _selectedCategoryId == cat.id,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedCategoryId = selected ? cat.id : null;
                                      });
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }
                      return const SizedBox(height: 44);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Products Grid
                  Expanded(
                    child: BlocBuilder<ProductsCubit, ProductsState>(
                      builder: (context, state) {
                        if (state is ProductsLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (state is ProductsLoaded) {
                          var products = state.products;

                          // Filter by Category
                          if (_selectedCategoryId != null) {
                            products = products.where((p) => p.categoryId == _selectedCategoryId).toList();
                          }

                          // Filter by Search Query
                          if (_productSearchQuery.isNotEmpty) {
                            final q = _productSearchQuery.toLowerCase();
                            products = products.where((p) {
                              final nameMatch = p.name.toLowerCase().contains(q);
                              final barcodeMatch = p.barcode != null && p.barcode!.contains(q);
                              return nameMatch || barcodeMatch;
                            }).toList();
                          }

                          if (products.isEmpty) {
                            return const Center(
                              child: Text('لا توجد منتجات مطابقة للبحث أو التصنيف'),
                            );
                          }

                          return GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1.25,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final p = products[index];
                              final isOut = p.currentQuantity <= 0;

                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isOut ? AppTheme.error.withValues(alpha: 0.3) : AppTheme.border,
                                  ),
                                ),
                                color: AppTheme.cardBackground,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () {
                                    context.read<SalesCubit>().addToCart(p);
                                    _barcodeFocusNode.requestFocus();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            if (p.barcode != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                p.barcode!,
                                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${p.sellPrice.toStringAsFixed(2)} ج',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: AppTheme.primary,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isOut
                                                    ? AppTheme.error.withValues(alpha: 0.12)
                                                    : AppTheme.success.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${p.currentQuantity}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isOut ? AppTheme.error : AppTheme.success,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }

                        return const SizedBox();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── RIGHT: Active Cart & Checkout ───
          Container(
            width: 440,
            decoration: const BoxDecoration(
              color: AppTheme.cardBackground,
              border: Border(
                right: BorderSide(color: AppTheme.border),
              ),
            ),
            child: BlocConsumer<SalesCubit, SalesState>(
              listener: (context, state) {
                if (state is SalesError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message), backgroundColor: AppTheme.error),
                  );
                }
              },
              builder: (context, state) {
                final pos = state is PosActiveState ? state : PosActiveState();

                return Column(
                  children: [
                    // Cart Top Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppTheme.border)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.shopping_cart_outlined, color: AppTheme.primary),
                              const SizedBox(width: 8),
                              const Text(
                                'سلة المبيعات',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${pos.cart.length} صنف',
                                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          if (pos.cart.isNotEmpty)
                            TextButton.icon(
                              onPressed: () => context.read<SalesCubit>().clearCart(),
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                              label: const Text('إفراغ', style: TextStyle(color: AppTheme.error)),
                            ),
                        ],
                      ),
                    ),

                    // Customer Selector Dropdown
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: BlocBuilder<CustomersCubit, CustomersState>(
                        builder: (context, custState) {
                          List<CustomerEntity> customers = [];
                          if (custState is CustomersLoaded) {
                            customers = custState.customers;
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<CustomerEntity?>(
                                  initialValue: pos.selectedCustomer,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'العميل (اختياري للبيع النقدي)',
                                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: [
                                    const DropdownMenuItem<CustomerEntity?>(
                                      value: null,
                                      child: Text('عميل نقدي / عام'),
                                    ),
                                    ...customers.map((c) => DropdownMenuItem<CustomerEntity?>(
                                          value: c,
                                          child: Text('${c.name} ${c.totalBalance > 0 ? "(${c.totalBalance.toStringAsFixed(0)} ج)" : ""}'),
                                        )),
                                  ],
                                  onChanged: (c) {
                                    context.read<SalesCubit>().selectCustomer(c);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.person_add_outlined, color: AppTheme.primary),
                                tooltip: 'إضافة عميل سريع',
                                onPressed: () => context.go(AppRoutes.customerAdd),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Cart Items List
                    Expanded(
                      child: pos.cart.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_shopping_cart, size: 54, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                                  const SizedBox(height: 12),
                                  const Text('السلة فارغة', style: TextStyle(color: AppTheme.textSecondary)),
                                  const SizedBox(height: 4),
                                  const Text('امسح باركود أو اضغط على صنف لإضافته', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: pos.cart.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = pos.cart[index];

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    children: [
                                      // Product Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.product.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${item.unitPrice.toStringAsFixed(2)} ج × ${item.quantity}',
                                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Quantity Controls (+ / -)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              context.read<SalesCubit>().updateQuantity(index, item.quantity - 1);
                                            },
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Text(
                                              item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline, size: 20),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              context.read<SalesCubit>().updateQuantity(index, item.quantity + 1);
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),

                                      // Total Item Price
                                      SizedBox(
                                        width: 70,
                                        child: Text(
                                          '${item.totalPrice.toStringAsFixed(2)} ج',
                                          textAlign: TextAlign.end,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),

                                      // Delete Item Button
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 18, color: AppTheme.error),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          context.read<SalesCubit>().removeFromCart(index);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    // Pricing Calculation Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppTheme.background,
                        border: Border(top: BorderSide(color: AppTheme.border)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('المجموع الفرعي:'),
                              Text('${pos.subtotal.toStringAsFixed(2)} ج', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('الخصم:'),
                              InkWell(
                                onTap: () => _showDiscountDialog(context, pos),
                                child: Text(
                                  pos.totalDiscount > 0 ? '- ${pos.totalDiscount.toStringAsFixed(2)} ج' : 'إضافة خصم',
                                  style: TextStyle(
                                    color: pos.totalDiscount > 0 ? AppTheme.error : AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('الإجمالي النهائي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(
                                '${pos.totalAmount.toStringAsFixed(2)} ج',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Payment Type Switcher
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text('نقدي (كاش)')),
                                  selected: pos.paymentType == 'cash',
                                  onSelected: (_) => context.read<SalesCubit>().setPaymentType('cash'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text('آجل (شكك)')),
                                  selected: pos.paymentType == 'credit',
                                  onSelected: (_) => context.read<SalesCubit>().setPaymentType('credit'),
                                ),
                              ),
                            ],
                          ),

                          // If Credit: Show Paid / Remaining Fields
                          if (pos.paymentType == 'credit') ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'المدفوع مقدماً (ج)',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onChanged: (val) {
                                      final p = double.tryParse(val) ?? 0.0;
                                      context.read<SalesCubit>().setPaidAmount(p);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.error.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('المتبقي على العميل:', style: TextStyle(fontSize: 11, color: AppTheme.error)),
                                        Text(
                                          '${pos.remainingAmount.toStringAsFixed(2)} ج',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 14),

                          // Complete Sale Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: (pos.cart.isEmpty || pos.isSubmitting)
                                  ? null
                                  : () => _handleCompleteSale(context),
                              icon: const Icon(Icons.check_circle_outline),
                              label: pos.isSubmitting
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('إتمام البيع وحفظ الفاتورة (F9)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.success,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog(BuildContext context, PosActiveState pos) {
    final amountController = TextEditingController(text: pos.discountAmount > 0 ? pos.discountAmount.toString() : '');
    final percentController = TextEditingController(text: pos.discountPercent > 0 ? pos.discountPercent.toString() : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة خصم على الفاتورة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'مبلغ الخصم (ج)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: percentController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'نسبة الخصم (%)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amountController.text) ?? 0.0;
              final pct = double.tryParse(percentController.text) ?? 0.0;
              context.read<SalesCubit>().setDiscount(amount: amt, percent: pct);
              Navigator.pop(ctx);
            },
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCompleteSale(BuildContext context) async {
    final saleId = await context.read<SalesCubit>().completeSale();

    if (saleId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إتمام البيع وحفظ الفاتورة بنجاح'),
          backgroundColor: AppTheme.success,
        ),
      );

      // Re-load products to update stock displays
      context.read<ProductsCubit>().loadProducts();

      // Offer to print receipt
      _showPrintReceiptDialog(context, saleId);

      _barcodeFocusNode.requestFocus();
    }
  }

  void _showPrintReceiptDialog(BuildContext context, int saleId) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.print_rounded, color: AppTheme.primary),
            SizedBox(width: 10),
            Text('طباعة الفاتورة'),
          ],
        ),
        content: const Text('هل تريد طباعة إيصال هذا البيع؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('لا، شكراً'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('طباعة الإيصال'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dlgCtx);
              // Navigate to sale detail for printing
              if (mounted) {
                context.go('${AppRoutes.sales}/$saleId');
              }
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print_rounded),
            label: const Text('طباعة سريعة (80mm)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dlgCtx);
              if (!mounted) return;
              try {
                final settingsState = context.read<SettingsCubit>().state;
                final settings = settingsState is SettingsLoaded
                    ? settingsState.settings
                    : ShopSettingsEntity.defaultSettings;
                final sale = await context.read<SalesCubit>().getSaleById(saleId);
                if (sale != null) {
                  await PdfInvoiceHelper.printReceipt(
                    sale: sale,
                    settings: settings,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('حدث خطأ أثناء الطباعة: $e'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
