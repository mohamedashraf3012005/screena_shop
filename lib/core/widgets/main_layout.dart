import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../routing/app_routes.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'factory_reset_dialog.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authCubit = context.watch<AuthCubit>();
    final user = authCubit.currentUser;
    final currentPath = GoRouterState.of(context).uri.path;

    // التحقق من صلاحيات المسار للمستخدم الحالي
    if (user != null) {
      if (user.role == 'cashier') {
        final isCashierAllowed = currentPath.startsWith(AppRoutes.sales) ||
            currentPath.startsWith(AppRoutes.pos) ||
            currentPath == AppRoutes.products ||
            currentPath.startsWith(AppRoutes.customers);
        if (!isCashierAllowed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go(AppRoutes.sales);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('غير مصرح لك بالدخول لهذه الصفحة (صلاحيات كاشير فقط)'),
                  backgroundColor: AppTheme.error,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          });
        }
      } else if (user.role == 'finance') {
        final isFinanceRestricted = currentPath.startsWith(AppRoutes.users) ||
            currentPath.startsWith(AppRoutes.settings);
        if (isFinanceRestricted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go(AppRoutes.dashboard);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('هذه الصفحة مخصصة لمدير النظام فقط'),
                  backgroundColor: AppTheme.error,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          });
        }
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Row(
          children: [
            // القائمة الجانبية (على اليمين لأن RTL)
            const AppSidebar(),
            // المحتوى الرئيسي
            Expanded(
              child: Column(
                children: [
                  const AppTopBar(),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// القائمة الجانبية
// ─────────────────────────────────────────────
class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.path;
    final authCubit = context.watch<AuthCubit>();
    final user = authCubit.currentUser;
    final role = user?.role ?? 'admin';
    final isCashier = role == 'cashier';
    final isAdmin = role == 'admin';

    return Container(
      width: 230,
      color: AppTheme.sidebarBg,
      child: Column(
        children: [
          // لوغو وعنوان
          _buildHeader(context),
          const SizedBox(height: 8),
          // عناصر القائمة حسب الصلاحية
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              children: [
                if (isCashier) ...[
                  const _SidebarSectionLabel('نقطة البيع'),
                  _SidebarItem(
                    icon: Icons.point_of_sale_outlined,
                    label: 'المبيعات والكاشير',
                    route: AppRoutes.sales,
                    currentRoute: currentLocation,
                  ),
                  const _SidebarDivider(),
                  const _SidebarSectionLabel('الاستعلامات'),
                  _SidebarItem(
                    icon: Icons.category_outlined,
                    label: 'المنتجات والأسعار',
                    route: AppRoutes.products,
                    currentRoute: currentLocation,
                  ),
                  _SidebarItem(
                    icon: Icons.people_outline,
                    label: 'العملاء والحسابات',
                    route: AppRoutes.customers,
                    currentRoute: currentLocation,
                  ),
                ] else ...[
                  _SidebarItem(
                    icon: Icons.dashboard_outlined,
                    label: 'لوحة التحكم',
                    route: AppRoutes.dashboard,
                    currentRoute: currentLocation,
                  ),
                  const _SidebarDivider(),
                  const _SidebarSectionLabel('العمليات'),
                  _SidebarItem(
                    icon: Icons.point_of_sale_outlined,
                    label: 'المبيعات',
                    route: AppRoutes.sales,
                    currentRoute: currentLocation,
                  ),
                  _SidebarItem(
                    icon: Icons.shopping_cart_outlined,
                    label: 'المشتريات',
                    route: AppRoutes.purchases,
                    currentRoute: currentLocation,
                  ),
                  const _SidebarDivider(),
                  const _SidebarSectionLabel('المخزون'),
                  _SidebarItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'المخزون',
                    route: AppRoutes.inventory,
                    currentRoute: currentLocation,
                  ),
                  _SidebarItem(
                    icon: Icons.category_outlined,
                    label: 'المنتجات',
                    route: AppRoutes.products,
                    currentRoute: currentLocation,
                  ),
                  _SidebarItem(
                    icon: Icons.label_outline,
                    label: 'التصنيفات',
                    route: AppRoutes.categories,
                    currentRoute: currentLocation,
                  ),
                  const _SidebarDivider(),
                  const _SidebarSectionLabel('الأطراف'),
                  _SidebarItem(
                    icon: Icons.people_outline,
                    label: 'العملاء',
                    route: AppRoutes.customers,
                    currentRoute: currentLocation,
                  ),
                  _SidebarItem(
                    icon: Icons.local_shipping_outlined,
                    label: 'الموردين',
                    route: AppRoutes.suppliers,
                    currentRoute: currentLocation,
                  ),
                  const _SidebarDivider(),
                  const _SidebarSectionLabel('المالية'),
                  _SidebarItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'الخزينة',
                    route: AppRoutes.treasury,
                    currentRoute: currentLocation,
                  ),
                  _SidebarItem(
                    icon: Icons.receipt_long_outlined,
                    label: 'المصروفات',
                    route: AppRoutes.expenses,
                    currentRoute: currentLocation,
                  ),
                  _SidebarItem(
                    icon: Icons.bar_chart_outlined,
                    label: 'التقارير',
                    route: AppRoutes.reports,
                    currentRoute: currentLocation,
                  ),
                  if (isAdmin) ...[
                    const _SidebarDivider(),
                    const _SidebarSectionLabel('الإدارة'),
                    _SidebarItem(
                      icon: Icons.manage_accounts_outlined,
                      label: 'المستخدمين',
                      route: AppRoutes.users,
                      currentRoute: currentLocation,
                    ),
                    _SidebarItem(
                      icon: Icons.settings_outlined,
                      label: 'الإعدادات',
                      route: AppRoutes.settings,
                      currentRoute: currentLocation,
                    ),
                  ],
                ],
              ],
            ),
          ),
          // تسجيل الخروج
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF2D3A4E)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.store_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Screena Shop',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'نظام الإدارة',
                  style: TextStyle(
                    color: AppTheme.sidebarItem,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final user = context.watch<AuthCubit>().currentUser;
    final isAdmin = user == null || user.isAdmin;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF2D3A4E))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAdmin) ...[
            InkWell(
              onTap: () => showFactoryResetDialog(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.error.withValues(alpha: 0.35)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.restart_alt_rounded, color: AppTheme.error, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ترجيع الكل كما كان',
                        style: TextStyle(
                          color: AppTheme.error,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          InkWell(
            onTap: () {
              context.read<AuthCubit>().logout();
              context.go(AppRoutes.login);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: const Row(
                children: [
                  Icon(Icons.logout, color: AppTheme.sidebarItem, size: 18),
                  SizedBox(width: 10),
                  Text(
                    'تسجيل الخروج',
                    style: TextStyle(
                      color: AppTheme.sidebarItem,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  bool get _isActive {
    if (widget.route == AppRoutes.dashboard) {
      return widget.currentRoute == '/';
    }
    return widget.currentRoute.startsWith(widget.route);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.go(widget.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _isActive
                ? AppTheme.sidebarItemActiveBg
                : _isHovered
                    ? AppTheme.sidebarItemHover
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: _isActive
                ? Border.all(color: AppTheme.primary.withValues(alpha: 0.3))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: _isActive
                    ? AppTheme.primary
                    : _isHovered
                        ? Colors.white
                        : AppTheme.sidebarItem,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  color: _isActive
                      ? Colors.white
                      : _isHovered
                          ? Colors.white
                          : AppTheme.sidebarItem,
                  fontSize: 13.5,
                  fontWeight: _isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (_isActive) ...[
                const Spacer(),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarDivider extends StatelessWidget {
  const _SidebarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      color: const Color(0xFF2D3A4E),
    );
  }
}

class _SidebarSectionLabel extends StatelessWidget {
  final String label;
  const _SidebarSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF5A6A7E),
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// الشريط العلوي
// ─────────────────────────────────────────────
class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          // العنوان الحالي
          _buildPageTitle(context),
          const Spacer(),
          // POS سريع
          _buildQuickPOSButton(context),
          const SizedBox(width: 12),
          // التاريخ والوقت
          _buildDateTime(),
          const SizedBox(width: 16),
          // معلومات المستخدم
          _buildUserInfo(context),
        ],
      ),
    );
  }

  Widget _buildPageTitle(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final title = _getPageTitle(location);
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  String _getPageTitle(String location) {
    if (location == '/') return 'لوحة التحكم';
    if (location.startsWith('/products')) return 'المنتجات';
    if (location.startsWith('/categories')) return 'التصنيفات';
    if (location.startsWith('/pos')) return 'نقطة البيع';
    if (location.startsWith('/sales')) return 'المبيعات';
    if (location.startsWith('/purchases')) return 'المشتريات';
    if (location.startsWith('/inventory')) return 'المخزون';
    if (location.startsWith('/customers')) return 'العملاء';
    if (location.startsWith('/suppliers')) return 'الموردين';
    if (location.startsWith('/treasury')) return 'الخزينة';
    if (location.startsWith('/expenses')) return 'المصروفات';
    if (location.startsWith('/reports')) return 'التقارير';
    if (location.startsWith('/users')) return 'المستخدمين';
    if (location.startsWith('/settings')) return 'الإعدادات';
    return '';
  }

  Widget _buildQuickPOSButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => context.go(AppRoutes.pos),
      icon: const Icon(Icons.point_of_sale_outlined, size: 16),
      label: const Text('بيع سريع'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.success,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildDateTime() {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, _) {
        final now = DateTime.now();
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${now.day}/${now.month}/${now.year}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textHint,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        final userName = user?.fullName ?? 'المستخدم';
        final role = user?.role ?? 'admin';

        String roleText = 'مدير عام';
        Color roleColor = Colors.purple;
        if (role == 'cashier') {
          roleText = 'كاشير';
          roleColor = Colors.blue;
        } else if (role == 'finance') {
          roleText = 'محاسب';
          roleColor = Colors.teal;
        }

        return Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.person_outline, size: 18, color: roleColor),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  userName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    roleText,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: roleColor),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
