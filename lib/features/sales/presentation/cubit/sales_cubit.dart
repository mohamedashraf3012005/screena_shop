import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/sale_entity.dart';
import '../../domain/repositories/sales_repository.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/domain/repositories/products_repository.dart';
import '../../../customers/domain/entities/customer_entity.dart';

class CartItem extends Equatable {
  final ProductEntity product;
  final double quantity;
  final double unitPrice;
  final double costPrice;
  final double discountAmount;
  final String priceType; // unit, group

  const CartItem({
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.costPrice,
    this.discountAmount = 0.0,
    this.priceType = 'unit',
  });

  double get totalPrice => (quantity * unitPrice) - discountAmount;
  double get totalCost => quantity * costPrice;
  double get profit => totalPrice - totalCost;

  CartItem copyWith({
    ProductEntity? product,
    double? quantity,
    double? unitPrice,
    double? costPrice,
    double? discountAmount,
    String? priceType,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      discountAmount: discountAmount ?? this.discountAmount,
      priceType: priceType ?? this.priceType,
    );
  }

  @override
  List<Object?> get props => [product.id, quantity, unitPrice, discountAmount, priceType];
}

// ─── States ───
abstract class SalesState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SalesInitial extends SalesState {}

class SalesLoading extends SalesState {}

class SalesLoaded extends SalesState {
  final List<SaleEntity> sales;
  SalesLoaded(this.sales);
  @override
  List<Object?> get props => [sales];
}

class PosActiveState extends SalesState {
  final List<CartItem> cart;
  final CustomerEntity? selectedCustomer;
  final double discountAmount;
  final double discountPercent;
  final String paymentType; // 'cash' or 'credit'
  final double paidAmount;
  final bool isSubmitting;
  final int? lastCreatedSaleId;

  PosActiveState({
    this.cart = const [],
    this.selectedCustomer,
    this.discountAmount = 0.0,
    this.discountPercent = 0.0,
    this.paymentType = 'cash',
    this.paidAmount = 0.0,
    this.isSubmitting = false,
    this.lastCreatedSaleId,
  });

  double get subtotal => cart.fold(0.0, (sum, item) => sum + (item.quantity * item.unitPrice));
  double get totalDiscount => discountAmount + (subtotal * discountPercent / 100);
  double get totalAmount => (subtotal - totalDiscount) > 0 ? (subtotal - totalDiscount) : 0.0;
  double get remainingAmount => (totalAmount - (paymentType == 'cash' ? totalAmount : paidAmount)) > 0
      ? (totalAmount - (paymentType == 'cash' ? totalAmount : paidAmount))
      : 0.0;
  double get totalCost => cart.fold(0.0, (sum, item) => sum + item.totalCost);
  double get totalProfit => totalAmount - totalCost;

  PosActiveState copyWith({
    List<CartItem>? cart,
    CustomerEntity? selectedCustomer,
    bool clearCustomer = false,
    double? discountAmount,
    double? discountPercent,
    String? paymentType,
    double? paidAmount,
    bool? isSubmitting,
    int? lastCreatedSaleId,
  }) {
    return PosActiveState(
      cart: cart ?? this.cart,
      selectedCustomer: clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercent: discountPercent ?? this.discountPercent,
      paymentType: paymentType ?? this.paymentType,
      paidAmount: paidAmount ?? this.paidAmount,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      lastCreatedSaleId: lastCreatedSaleId,
    );
  }

  @override
  List<Object?> get props => [
        cart,
        selectedCustomer,
        discountAmount,
        discountPercent,
        paymentType,
        paidAmount,
        isSubmitting,
        lastCreatedSaleId,
      ];
}

class SalesError extends SalesState {
  final String message;
  SalesError(this.message);
  @override
  List<Object?> get props => [message];
}

class SalesCubit extends Cubit<SalesState> {
  final SalesRepository _salesRepository;
  final ProductsRepository _productsRepository;

  PosActiveState _posState = PosActiveState();
  PosActiveState get posState => _posState;

  SalesCubit(
    this._salesRepository,
    this._productsRepository,
  ) : super(SalesInitial());

  // ─── POS Actions ───
  void initPos() {
    _posState = PosActiveState();
    emit(_posState);
  }

  void addToCart(ProductEntity product, {double quantity = 1, bool isWholesale = false}) {
    final existingIndex = _posState.cart.indexWhere((i) => i.product.id == product.id && i.priceType == (isWholesale ? 'group' : 'unit'));

    final price = isWholesale ? (product.groupPrice > 0 ? product.groupPrice : product.sellPrice) : product.sellPrice;
    final cost = product.costPrice;

    List<CartItem> newCart = List.from(_posState.cart);

    if (existingIndex >= 0) {
      final existing = newCart[existingIndex];
      newCart[existingIndex] = existing.copyWith(quantity: existing.quantity + quantity);
    } else {
      newCart.add(CartItem(
        product: product,
        quantity: quantity,
        unitPrice: price,
        costPrice: cost,
        priceType: isWholesale ? 'group' : 'unit',
      ));
    }

    _posState = _posState.copyWith(
      cart: newCart,
      paidAmount: _posState.paymentType == 'cash' ? null : _posState.paidAmount,
    );
    emit(_posState);
  }

  Future<bool> addByBarcode(String barcode) async {
    try {
      final product = await _productsRepository.getByBarcode(barcode.trim());
      if (product != null) {
        addToCart(product);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void updateQuantity(int index, double quantity) {
    if (quantity <= 0) {
      removeFromCart(index);
      return;
    }
    List<CartItem> newCart = List.from(_posState.cart);
    newCart[index] = newCart[index].copyWith(quantity: quantity);
    _posState = _posState.copyWith(cart: newCart);
    emit(_posState);
  }

  void updateItemPrice(int index, double newPrice) {
    List<CartItem> newCart = List.from(_posState.cart);
    newCart[index] = newCart[index].copyWith(unitPrice: newPrice);
    _posState = _posState.copyWith(cart: newCart);
    emit(_posState);
  }

  void removeFromCart(int index) {
    List<CartItem> newCart = List.from(_posState.cart);
    newCart.removeAt(index);
    _posState = _posState.copyWith(cart: newCart);
    emit(_posState);
  }

  void clearCart() {
    _posState = PosActiveState();
    emit(_posState);
  }

  void selectCustomer(CustomerEntity? customer) {
    _posState = _posState.copyWith(
      selectedCustomer: customer,
      clearCustomer: customer == null,
    );
    emit(_posState);
  }

  void setDiscount({double? amount, double? percent}) {
    _posState = _posState.copyWith(
      discountAmount: amount ?? _posState.discountAmount,
      discountPercent: percent ?? _posState.discountPercent,
    );
    emit(_posState);
  }

  void setPaymentType(String type) {
    _posState = _posState.copyWith(
      paymentType: type,
      paidAmount: type == 'cash' ? _posState.totalAmount : 0.0,
    );
    emit(_posState);
  }

  void setPaidAmount(double amount) {
    _posState = _posState.copyWith(paidAmount: amount);
    emit(_posState);
  }

  Future<int?> completeSale({String? notes, int? userId}) async {
    if (_posState.cart.isEmpty) return null;

    if (_posState.paymentType == 'credit' && _posState.selectedCustomer == null) {
      emit(SalesError('لا يمكن إتمام بيع آجل (شكك) بدون تحديد العميل'));
      emit(_posState);
      return null;
    }

    _posState = _posState.copyWith(isSubmitting: true);
    emit(_posState);

    try {
      final effectivePaid = _posState.paymentType == 'cash' ? _posState.totalAmount : _posState.paidAmount;
      final effectiveRemaining = _posState.totalAmount - effectivePaid;

      final sale = SaleEntity(
        id: 0,
        invoiceNumber: '',
        customerId: _posState.selectedCustomer?.id,
        subtotal: _posState.subtotal,
        discountAmount: _posState.totalDiscount,
        discountPercent: _posState.discountPercent,
        totalAmount: _posState.totalAmount,
        paidAmount: effectivePaid,
        remainingAmount: effectiveRemaining > 0 ? effectiveRemaining : 0.0,
        costAmount: _posState.totalCost,
        profitAmount: _posState.totalProfit,
        paymentType: _posState.paymentType,
        status: 'completed',
        notes: notes,
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final items = _posState.cart
          .map((c) => SaleItemEntity(
                id: 0,
                saleId: 0,
                productId: c.product.id,
                productName: c.product.name,
                productBarcode: c.product.barcode,
                quantity: c.quantity,
                unitPrice: c.unitPrice,
                costPrice: c.costPrice,
                discountAmount: c.discountAmount,
                totalPrice: c.totalPrice,
                totalCost: c.totalCost,
                profitAmount: c.profit,
                priceType: c.priceType,
              ))
          .toList();

      final saleId = await _salesRepository.createSale(sale: sale, items: items);

      _posState = PosActiveState(lastCreatedSaleId: saleId);
      emit(_posState);
      return saleId;
    } catch (e) {
      _posState = _posState.copyWith(isSubmitting: false);
      emit(SalesError('حدث خطأ أثناء حفظ الفاتورة'));
      emit(_posState);
      return null;
    }
  }

  // ─── Invoices Log / Archive ───
  Future<void> loadSales({
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
    int? customerId,
  }) async {
    emit(SalesLoading());
    try {
      final sales = await _salesRepository.getAllSales(
        search: search,
        fromDate: fromDate,
        toDate: toDate,
        customerId: customerId,
      );
      emit(SalesLoaded(sales));
    } catch (e) {
      emit(SalesError('حدث خطأ أثناء تحميل سجل المبيعات'));
    }
  }

  Future<SaleEntity?> getSaleById(int id) async {
    try {
      return await _salesRepository.getSaleById(id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> cancelSale({required int id, required String reason, int? userId}) async {
    try {
      final success = await _salesRepository.cancelSale(id: id, reason: reason, userId: userId);
      await loadSales();
      return success;
    } catch (e) {
      emit(SalesError('حدث خطأ أثناء إلغاء الفاتورة'));
      return false;
    }
  }
}
