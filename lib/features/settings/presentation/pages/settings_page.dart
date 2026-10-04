import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/settings_cubit.dart';
import '../../domain/entities/settings_entity.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _currencyController = TextEditingController();
  final _footerController = TextEditingController();
  final _taxRateController = TextEditingController();
  final _lowStockThresholdController = TextEditingController();

  bool _allowNegativeStock = false;
  bool _taxEnabled = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    context.read<SettingsCubit>().loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _currencyController.dispose();
    _footerController.dispose();
    _taxRateController.dispose();
    _lowStockThresholdController.dispose();
    super.dispose();
  }

  void _populateForm(ShopSettingsEntity s) {
    _nameController.text = s.shopName;
    _phoneController.text = s.shopPhone;
    _addressController.text = s.shopAddress;
    _currencyController.text = s.currency;
    _footerController.text = s.invoiceFooter;
    _taxRateController.text = s.taxRate.toString();
    _lowStockThresholdController.text = s.lowStockThreshold.toString();
    _allowNegativeStock = s.allowNegativeStock;
    _taxEnabled = s.taxEnabled;
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final updated = ShopSettingsEntity(
      shopName: _nameController.text.trim(),
      shopPhone: _phoneController.text.trim(),
      shopAddress: _addressController.text.trim(),
      currency: _currencyController.text.trim(),
      currencyDecimals: 2,
      allowNegativeStock: _allowNegativeStock,
      lowStockThreshold: double.tryParse(_lowStockThresholdController.text.trim()) ?? 10.0,
      invoiceFooter: _footerController.text.trim(),
      taxRate: double.tryParse(_taxRateController.text.trim()) ?? 0.0,
      taxEnabled: _taxEnabled,
      backupPath: '',
    );

    final success = await context.read<SettingsCubit>().updateSettings(updated);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الإعدادات بنجاح'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  Future<void> _takeBackup() async {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'اختر المجلد لحفظ النسخة الاحتياطية',
    );

    if (dir != null && mounted) {
      final path = await context.read<SettingsCubit>().backupDatabase(dir);
      if (path != null && mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('تم أخذ النسخة الاحتياطية بنجاح'),
            content: Text('تم حفظ ملف النسخة الاحتياطية في:\n$path'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً')),
            ],
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('حدث خطأ أثناء أخذ النسخة الاحتياطية')),
          );
        }
      }
    }
  }

  Future<void> _restoreBackup() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'اختر ملف قاعدة البيانات لاستعادته (.db)',
      type: FileType.custom,
      allowedExtensions: ['db'],
    );

    if (result != null && result.files.single.path != null && mounted) {
      final filePath = result.files.single.path!;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تأكيد استعادة النسخة الاحتياطية'),
          content: const Text(
            'تحذير: ستؤدي استعادة النسخة الاحتياطية إلى استبدال جميع البيانات الحالية بالبيانات الموجودة في الملف المختار. يرجى التأكد قبل المتابعة.',
            style: TextStyle(color: AppTheme.error),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await context.read<SettingsCubit>().restoreDatabase(filePath);
                if (mounted && success) {
                  showDialog(
                    context: context,
                    builder: (d) => AlertDialog(
                      title: const Text('تمت الاستعادة بنجاح'),
                      content: const Text('تمت استعادة البيانات بنجاح. يرجى إعادة تشغيل التطبيق لتحديث جميع الشاشات.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(d), child: const Text('حسناً')),
                      ],
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
              child: const Text('تأكيد الاستعادة'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
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
                      'إعدادات النظام والنسخ الاحتياطي',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تخصيص بيانات المحل، الفاتورة، الضرائب، والنسخ الاحتياطي لقاعدة البيانات',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveSettings,
                  icon: const Icon(Icons.save),
                  label: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('حفظ جميع الإعدادات'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            BlocConsumer<SettingsCubit, SettingsState>(
              listener: (context, state) {
                if (state is SettingsLoaded) {
                  _populateForm(state.settings);
                }
              },
              builder: (context, state) {
                if (state is SettingsLoading) {
                  return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator()));
                }

                return Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Store Info Section
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
                              const Row(
                                children: [
                                  Icon(Icons.storefront_outlined, color: AppTheme.primary, size: 24),
                                  SizedBox(width: 10),
                                  Text(
                                    'بيانات المحل أو الشركة',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _nameController,
                                      decoration: const InputDecoration(
                                        labelText: 'اسم المحل / الشركة *',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _phoneController,
                                      decoration: const InputDecoration(
                                        labelText: 'رقم الهاتف للتواصل',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _addressController,
                                decoration: const InputDecoration(
                                  labelText: 'عنوان المحل أو المقر الرئيسي',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Invoices & Currency Section
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
                              const Row(
                                children: [
                                  Icon(Icons.receipt_long_outlined, color: AppTheme.primary, size: 24),
                                  SizedBox(width: 10),
                                  Text(
                                    'إعدادات الفواتير والعملة',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _currencyController,
                                      decoration: const InputDecoration(
                                        labelText: 'رمز العملة المستخدمة',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _lowStockThresholdController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'حد تنبيه النواقص العام (الافتراضي)',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _footerController,
                                decoration: const InputDecoration(
                                  labelText: 'عبارة أسفل الفاتورة (الذيل)',
                                  hintText: 'مثال: شكراً لزيارتكم - البضاعة المباعة ترد خلال 14 يوم...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SwitchListTile(
                                title: const Text('السماح بالبيع بالسالب (بدون رصيد كاف بالمخزن)'),
                                subtitle: const Text('في حال التفعيل، يمكن إتمام المبيعات حتى وإن كان الرصيد صفراً'),
                                value: _allowNegativeStock,
                                onChanged: (v) => setState(() => _allowNegativeStock = v),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Backup & Restore Database Section
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
                              const Row(
                                children: [
                                  Icon(Icons.backup_outlined, color: AppTheme.primary, size: 24),
                                  SizedBox(width: 10),
                                  Text(
                                    'النسخ الاحتياطي وحماية البيانات (Offline Database Backup)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              const Text(
                                'يمكنك أخذ نسخة كاملة من قاعدة بيانات النظام محلياً وحفظها على قرص خارجي (فلاشة / هارديسك) أو سحابة لضمان عدم ضياع أي بيانات إطلاقاً.',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _takeBackup,
                                    icon: const Icon(Icons.download),
                                    label: const Text('أخذ نسخة احتياطية الآن (Backup)'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  OutlinedButton.icon(
                                    onPressed: _restoreBackup,
                                    icon: const Icon(Icons.restore, color: AppTheme.error),
                                    label: const Text('استعادة نسخة احتياطية سابقة (Restore)', style: TextStyle(color: AppTheme.error)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppTheme.error),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
