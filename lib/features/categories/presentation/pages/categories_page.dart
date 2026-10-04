import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../cubit/categories_cubit.dart';
import '../../domain/entities/category_entity.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CategoriesCubit>()..loadCategories(),
      child: const _CategoriesView(),
    );
  }
}

class _CategoriesView extends StatelessWidget {
  const _CategoriesView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // التصنيفات
          Expanded(
            child: _CategoriesPanel(),
          ),
          const SizedBox(width: 20),
          // الأنواع
          Expanded(
            child: _TypesPanel(),
          ),
        ],
      ),
    );
  }
}

class _CategoriesPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _PanelHeader(
            title: 'التصنيفات',
            onAdd: () => _showCategoryDialog(context),
          ),
          Expanded(
            child: BlocBuilder<CategoriesCubit, CategoriesState>(
              builder: (context, state) {
                if (state is CategoriesLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is CategoriesLoaded) {
                  if (state.categories.isEmpty) {
                    return const Center(
                      child: Text('لا توجد تصنيفات',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, i) =>
                        _CategoryItem(category: state.categories[i]),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, [CategoryEntity? category]) {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController(text: category?.name);
    final descCtrl = TextEditingController(text: category?.description);
    final cubit = context.read<CategoriesCubit>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(category == null ? 'إضافة تصنيف' : 'تعديل التصنيف'),
          content: SizedBox(
            width: 360,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: ctrl,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'اسم التصنيف *'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'يرجى إدخال اسم التصنيف';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'الوصف'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);
                      final name = ctrl.text.trim();
                      final desc = descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim();
                      final ok = category == null
                          ? await cubit.createCategory(name, desc)
                          : await cubit.updateCategory(category.id, name, desc);
                      if (!dlgCtx.mounted) return;
                      if (ok) {
                        Navigator.pop(dlgCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(category == null
                                ? 'تمت إضافة التصنيف "$name" بنجاح'
                                : 'تم تعديل التصنيف "$name" بنجاح'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      } else {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(dlgCtx).showSnackBar(
                          const SnackBar(
                            content: Text('حدث خطأ أثناء حفظ التصنيف، يرجى المحاولة مرة أخرى'),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem extends StatefulWidget {
  final CategoryEntity category;
  const _CategoryItem({required this.category});

  @override
  State<_CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<_CategoryItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.surfaceVariant : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.label_outline, size: 18, color: AppTheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.category.name,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    '${widget.category.productCount} منتج',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textHint),
                  ),
                ],
              ),
            ),
            if (_isHovered) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16),
                onPressed: () => _showEdit(context),
                tooltip: 'تعديل',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 16,
                    color: AppTheme.error),
                onPressed: () => _confirmDelete(context),
                tooltip: 'حذف',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEdit(BuildContext context) {
    final ctrl = TextEditingController(text: widget.category.name);
    final descCtrl = TextEditingController(text: widget.category.description);
    // Capture cubit before async gap
    final cubit = context.read<CategoriesCubit>();
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('تعديل التصنيف'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'اسم التصنيف *'),
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'الوصف'),
                  maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              final ok = await cubit.updateCategory(
                  widget.category.id,
                  ctrl.text.trim(),
                  descCtrl.text.isEmpty ? null : descCtrl.text);
              if (ok && dlgCtx.mounted) Navigator.pop(dlgCtx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<CategoriesCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('حذف التصنيف'),
        content: Text('هل تريد حذف "${widget.category.name}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dlgCtx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dlgCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await cubit.deleteCategory(widget.category.id);
    }
  }
}

class _TypesPanel extends StatefulWidget {
  @override
  State<_TypesPanel> createState() => _TypesPanelState();
}

class _TypesPanelState extends State<_TypesPanel> {
  int? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _PanelHeader(
            title: 'الأنواع',
            onAdd: () => _showTypeDialog(context),
          ),
          // فلتر التصنيف
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: BlocBuilder<CategoriesCubit, CategoriesState>(
              builder: (context, state) {
                final categories = state is CategoriesLoaded
                    ? state.categories
                    : <CategoryEntity>[];
                final validFilterId = (_selectedCategoryId != null &&
                        categories.any((c) => c.id == _selectedCategoryId))
                    ? _selectedCategoryId
                    : null;
                return DropdownButtonFormField<int?>(
                  key: ValueKey(validFilterId),
                  initialValue: validFilterId,
                  decoration: const InputDecoration(
                    labelText: 'تصفية بالتصنيف',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                        value: null, child: Text('كل التصنيفات')),
                    ...categories.map((c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text(c.name),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<CategoriesCubit, CategoriesState>(
              builder: (context, state) {
                if (state is CategoriesLoaded) {
                  final filtered = _selectedCategoryId == null
                      ? state.types
                      : state.types
                          .where(
                              (t) => t.categoryId == _selectedCategoryId)
                          .toList();
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('لا توجد أنواع',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, i) =>
                        _TypeItem(type: filtered[i]),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showTypeDialog(BuildContext context) {
    final cubit = context.read<CategoriesCubit>();
    final state = cubit.state;
    final categories =
        state is CategoriesLoaded ? state.categories : <CategoryEntity>[];
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إضافة تصنيف أولاً قبل إضافة الأنواع'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }
    int? catId = (_selectedCategoryId != null && categories.any((c) => c.id == _selectedCategoryId))
        ? _selectedCategoryId
        : categories.first.id;
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('إضافة نوع جديد'),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int?>(
                    key: ValueKey(catId),
                    initialValue: catId,
                    decoration: const InputDecoration(
                      labelText: 'التصنيف التابع له *',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: categories
                        .map((c) => DropdownMenuItem<int?>(
                              value: c.id,
                              child: Text(c.name),
                            ))
                        .toList(),
                    onChanged: (v) => setDialogState(() => catId = v),
                    validator: (v) => v == null ? 'يرجى اختيار التصنيف' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'اسم النوع *',
                      hintText: 'مثال: شاشات سمارت، مياه غازية...',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'يرجى إدخال اسم النوع';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'الوصف (اختياري)',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      if (catId == null) return;
                      setDialogState(() => isSaving = true);
                      final name = nameCtrl.text.trim();
                      final desc = descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim();
                      final ok = await cubit.createType(catId!, name, desc);
                      if (!dlgCtx.mounted) return;
                      if (ok) {
                        Navigator.pop(dlgCtx);
                        if (mounted) {
                          setState(() {
                            _selectedCategoryId = catId;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تمت إضافة النوع "$name" بنجاح'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        }
                      } else {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(dlgCtx).showSnackBar(
                          const SnackBar(
                            content: Text('حدث خطأ أثناء إضافة النوع، يرجى المحاولة مرة أخرى'),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeItem extends StatefulWidget {
  final ProductTypeEntity type;
  const _TypeItem({required this.type});

  @override
  State<_TypeItem> createState() => _TypeItemState();
}

class _TypeItemState extends State<_TypeItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.surfaceVariant : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.chevron_left, size: 14, color: AppTheme.textHint),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.type.name,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    '${widget.type.categoryName} • ${widget.type.productCount} منتج',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textHint),
                  ),
                ],
              ),
            ),
            if (_isHovered) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16),
                onPressed: () => _showEdit(context),
                tooltip: 'تعديل',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 16, color: AppTheme.error),
                onPressed: () => _confirmDelete(context),
                tooltip: 'حذف',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEdit(BuildContext context) {
    final ctrl = TextEditingController(text: widget.type.name);
    final cubit = context.read<CategoriesCubit>();
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('تعديل النوع'),
        content: SizedBox(
          width: 360,
          child: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'اسم النوع *'),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              final ok = await cubit.updateType(widget.type.id, ctrl.text.trim(), null);
              if (ok && dlgCtx.mounted) Navigator.pop(dlgCtx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<CategoriesCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('حذف النوع'),
        content: Text('هل تريد حذف "${widget.type.name}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dlgCtx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dlgCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await cubit.deleteType(widget.type.id);
    }
  }
}

class _PanelHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;

  const _PanelHeader({required this.title, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('إضافة'),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}
