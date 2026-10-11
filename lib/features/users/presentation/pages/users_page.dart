import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/di/injection_container.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final AppDatabase _db = sl<AppDatabase>();
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await _db.select(_db.users).get();
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> _showAddUserDialog() async {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'cashier';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('إضافة مستخدم جديد للنظام'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'الاسم الكامل *', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: 'اسم الدخول (Username) *', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'كلمة المرور *', border: OutlineInputBorder()),
                    validator: (v) => v!.length < 4 ? '4 حروف على الأقل' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: 'الصلاحية / الدور *', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('مدير نظام (كامل الصلاحيات)')),
                      DropdownMenuItem(value: 'cashier', child: Text('كاشير (نقطة البيع والمبيعات)')),
                      DropdownMenuItem(value: 'finance', child: Text('محاسب (الخزينة والمصروفات والتقارير)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedRole = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final hash = _hashPassword(passwordController.text);

                await _db.into(_db.users).insert(
                      UsersCompanion.insert(
                        username: usernameController.text.trim(),
                        fullName: nameController.text.trim(),
                        passwordHash: hash,
                        role: selectedRole,
                      ),
                    );

                if (mounted) {
                  Navigator.pop(ctx);
                  _loadUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تمت إضافة المستخدم بنجاح'), backgroundColor: AppTheme.success),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              child: const Text('حفظ المستخدم'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleUserActive(User user) async {
    await (_db.update(_db.users)..where((u) => u.id.equals(user.id))).write(
      UsersCompanion(isActive: drift.Value(!user.isActive)),
    );
    _loadUsers();
  }

  Future<void> _showEditUserDialog(User user) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user.fullName);
    final passwordController = TextEditingController();
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('تعديل المستخدم: ${user.fullName}'),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('اسم الدخول: ${user.username}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'الاسم الكامل *', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: 'الصلاحية / الدور *', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('مدير عام (كامل الصلاحيات والإدارة)')),
                      DropdownMenuItem(value: 'cashier', child: Text('كاشير (نقطة البيع والمبيعات فقط)')),
                      DropdownMenuItem(value: 'finance', child: Text('محاسب (الخزينة والمصروفات والتقارير)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedRole = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'كلمة مرور جديدة (اتركها فارغة إن لم ترغب في التغيير)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                drift.Value<String> passVal = const drift.Value.absent();
                if (passwordController.text.trim().isNotEmpty) {
                  passVal = drift.Value(_hashPassword(passwordController.text.trim()));
                }

                await (_db.update(_db.users)..where((u) => u.id.equals(user.id))).write(
                  UsersCompanion(
                    fullName: drift.Value(nameController.text.trim()),
                    role: drift.Value(selectedRole),
                    passwordHash: passVal,
                  ),
                );

                if (mounted) {
                  Navigator.pop(ctx);
                  _loadUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تحديث بيانات المستخدم بنجاح'), backgroundColor: AppTheme.success),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              child: const Text('حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المستخدم'),
        content: Text('هل أنت متأكد من حذف المستخدم "${user.fullName}" (${user.username})؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await (_db.delete(_db.users)..where((u) => u.id.equals(user.id))).go();
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المستخدم بنجاح'), backgroundColor: AppTheme.success),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
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
                      'إدارة المستخدمين والصلاحيات',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'إدارة حسابات الكاشير، المحاسب، والمدير، وتعيين الأدوار',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddUserDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text('إضافة مستخدم جديد'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Users Table
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
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
                                DataColumn(label: Text('الاسم الكامل', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('اسم الدخول', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('الصلاحية', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: _users.asMap().entries.map((entry) {
                                final index = entry.key + 1;
                                final u = entry.value;

                                String roleLabel = 'كاشير';
                                Color roleColor = Colors.blue;
                                if (u.role == 'admin') {
                                  roleLabel = 'مدير عام';
                                  roleColor = Colors.purple;
                                } else if (u.role == 'finance') {
                                  roleLabel = 'محاسب';
                                  roleColor = Colors.teal;
                                }

                                return DataRow(
                                  cells: [
                                    DataCell(Text('$index')),
                                    DataCell(Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(Text(u.username)),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: roleColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          roleLabel,
                                          style: TextStyle(fontWeight: FontWeight.bold, color: roleColor),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        u.isActive ? 'نشط' : 'معطل',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: u.isActive ? AppTheme.success : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18),
                                            tooltip: 'تعديل الصلاحية والبيانات',
                                            color: AppTheme.primary,
                                            onPressed: () => _showEditUserDialog(u),
                                          ),
                                          if (u.username != 'admin') ...[
                                            IconButton(
                                              icon: Icon(u.isActive ? Icons.block : Icons.check_circle_outline, size: 18),
                                              tooltip: u.isActive ? 'تعطيل الحساب' : 'تفعيل الحساب',
                                              color: u.isActive ? AppTheme.warning : AppTheme.success,
                                              onPressed: () => _toggleUserActive(u),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, size: 18),
                                              tooltip: 'حذف المستخدم',
                                              color: AppTheme.error,
                                              onPressed: () => _deleteUser(u),
                                            ),
                                          ],
                                        ],
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
      ),
    );
  }
}
