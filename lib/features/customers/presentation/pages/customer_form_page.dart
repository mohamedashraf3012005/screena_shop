import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_routes.dart';
import '../cubit/customers_cubit.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerFormPage extends StatefulWidget {
  final int? customerId;

  const CustomerFormPage({super.key, this.customerId});

  @override
  State<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _balanceController = TextEditingController(text: '0.0');

  bool _isActive = true;
  bool _isLoading = false;
  CustomerEntity? _existingCustomer;

  bool get isEditing => widget.customerId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadCustomer();
    }
  }

  Future<void> _loadCustomer() async {
    setState(() => _isLoading = true);
    final customer = await context.read<CustomersCubit>().getById(widget.customerId!);
    if (customer != null && mounted) {
      setState(() {
        _existingCustomer = customer;
        _nameController.text = customer.name;
        _phoneController.text = customer.phone ?? '';
        _whatsappController.text = customer.whatsapp ?? '';
        _addressController.text = customer.address ?? '';
        _notesController.text = customer.notes ?? '';
        _balanceController.text = customer.totalBalance.toString();
        _isActive = customer.isActive;
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final customer = CustomerEntity(
      id: widget.customerId ?? 0,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      whatsapp: _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      totalBalance: isEditing
          ? (_existingCustomer?.totalBalance ?? 0.0)
          : (double.tryParse(_balanceController.text.trim()) ?? 0.0),
      isActive: _isActive,
      createdAt: _existingCustomer?.createdAt ?? DateTime.now(),
      lastTransactionAt: _existingCustomer?.lastTransactionAt,
    );

    final success = await context.read<CustomersCubit>().save(customer);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'تم تحديث بيانات العميل بنجاح' : 'تم إضافة العميل بنجاح'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.go(AppRoutes.customers);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل بيانات عميل' : 'إضافة عميل جديد'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.customers),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Form(
                    key: _formKey,
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppTheme.border),
                      ),
                      color: AppTheme.cardBackground,
                      child: Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                                  foregroundColor: AppTheme.primary,
                                  radius: 24,
                                  child: const Icon(Icons.person, size: 28),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isEditing ? 'تعديل عميل: ${_existingCustomer?.name ?? ''}' : 'بيانات العميل الجديد',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text('أدخل البيانات الأساسية ومعلومات التواصل الخاصة بالعميل'),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 36),

                            // Name
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'اسم العميل *',
                                prefixIcon: Icon(Icons.badge_outlined),
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'اسم العميل مطلوب';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Phone & WhatsApp
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(
                                      labelText: 'رقم الهاتف',
                                      prefixIcon: Icon(Icons.phone_outlined),
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _whatsappController,
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(
                                      labelText: 'رقم واتساب',
                                      prefixIcon: Icon(Icons.chat_bubble_outline),
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Address
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'العنوان',
                                prefixIcon: Icon(Icons.location_on_outlined),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Initial Balance (only when adding new customer)
                            if (!isEditing) ...[
                              TextFormField(
                                controller: _balanceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'الرصيد الافتتاحي (المديونية السابقة)',
                                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                                  helperText: 'إذا كان على العميل مديونية سابقة قبل استخدام النظام، أدخلها هنا',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Notes
                            TextFormField(
                              controller: _notesController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'ملاحظات إضافية',
                                prefixIcon: Icon(Icons.notes_outlined),
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Active Status
                            SwitchListTile(
                              title: const Text('حساب العميل نشط'),
                              subtitle: const Text('الحسابات المعطلة لا تظهر في عمليات البيع السريع'),
                              value: _isActive,
                              onChanged: (val) => setState(() => _isActive = val),
                              contentPadding: EdgeInsets.zero,
                            ),
                            const SizedBox(height: 32),

                            // Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () => context.go(AppRoutes.customers),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  ),
                                  child: const Text('إلغاء'),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: _submit,
                                  icon: const Icon(Icons.save),
                                  label: Text(isEditing ? 'حفظ التعديلات' : 'إضافة العميل'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
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
