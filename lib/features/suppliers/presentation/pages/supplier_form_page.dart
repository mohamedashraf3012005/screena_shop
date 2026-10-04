import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_routes.dart';
import '../cubit/suppliers_cubit.dart';
import '../../domain/entities/supplier_entity.dart';

class SupplierFormPage extends StatefulWidget {
  final int? supplierId;

  const SupplierFormPage({super.key, this.supplierId});

  @override
  State<SupplierFormPage> createState() => _SupplierFormPageState();
}

class _SupplierFormPageState extends State<SupplierFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _balanceController = TextEditingController(text: '0.0');

  bool _isActive = true;
  bool _isLoading = false;
  SupplierEntity? _existingSupplier;

  bool get isEditing => widget.supplierId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadSupplier();
    }
  }

  Future<void> _loadSupplier() async {
    setState(() => _isLoading = true);
    final supplier = await context.read<SuppliersCubit>().getById(widget.supplierId!);
    if (supplier != null && mounted) {
      setState(() {
        _existingSupplier = supplier;
        _nameController.text = supplier.name;
        _companyController.text = supplier.company ?? '';
        _phoneController.text = supplier.phone ?? '';
        _whatsappController.text = supplier.whatsapp ?? '';
        _addressController.text = supplier.address ?? '';
        _notesController.text = supplier.notes ?? '';
        _balanceController.text = supplier.totalBalance.toString();
        _isActive = supplier.isActive;
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
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

    final supplier = SupplierEntity(
      id: widget.supplierId ?? 0,
      name: _nameController.text.trim(),
      company: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      whatsapp: _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      totalBalance: isEditing
          ? (_existingSupplier?.totalBalance ?? 0.0)
          : (double.tryParse(_balanceController.text.trim()) ?? 0.0),
      isActive: _isActive,
      createdAt: _existingSupplier?.createdAt ?? DateTime.now(),
      lastTransactionAt: _existingSupplier?.lastTransactionAt,
    );

    final success = await context.read<SuppliersCubit>().save(supplier);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'تم تحديث بيانات المورد بنجاح' : 'تم إضافة المورد بنجاح'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.go(AppRoutes.suppliers);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل بيانات مورد' : 'إضافة مورد جديد'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.suppliers),
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
                                  backgroundColor: Colors.amber.withValues(alpha: 0.15),
                                  foregroundColor: Colors.amber.shade900,
                                  radius: 24,
                                  child: const Icon(Icons.business, size: 28),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isEditing ? 'تعديل مورد: ${_existingSupplier?.name ?? ''}' : 'بيانات المورد الجديد',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text('أدخل اسم المورد واسم الشركة وبيانات التواصل'),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 36),

                            // Name & Company
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'اسم المورد أو المسؤول *',
                                      prefixIcon: Icon(Icons.person_outline),
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'اسم المورد مطلوب';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _companyController,
                                    decoration: const InputDecoration(
                                      labelText: 'اسم الشركة أو المصنع',
                                      prefixIcon: Icon(Icons.apartment_outlined),
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
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
                                labelText: 'العنوان أو الموقع',
                                prefixIcon: Icon(Icons.location_on_outlined),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Initial Balance (only when adding)
                            if (!isEditing) ...[
                              TextFormField(
                                controller: _balanceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'الرصيد الافتتاحي (المستحق للمورد)',
                                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                                  helperText: 'إذا كان للمورد مستحقات سابقة قبل استخدام النظام، أدخلها هنا',
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
                              title: const Text('حساب المورد نشط'),
                              subtitle: const Text('الموردون المعطلون لا يظهرون في فواتير الشراء السريعة'),
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
                                  onPressed: () => context.go(AppRoutes.suppliers),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  ),
                                  child: const Text('إلغاء'),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: _submit,
                                  icon: const Icon(Icons.save),
                                  label: Text(isEditing ? 'حفظ التعديلات' : 'إضافة المورد'),
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
