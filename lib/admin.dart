import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'config.dart';
import 'models.dart';
import 'providers.dart';
import 'services.dart';
import 'widgets.dart';

const _statuses = [
  'placed',
  'confirmed',
  'preparing',
  'ready',
  'delivered',
  'cancelled',
];

// ==================== ADMIN LOGIN ====================
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;

    if (_email.text.trim().toLowerCase() !=
        AppConfig.adminEmail.toLowerCase()) {
      Helpers.error(context, 'This email is not authorized as admin');
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService.signIn(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      Helpers.success(context, 'Welcome back, Admin');
      context.go('/admin');
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        Helpers.error(context, _errorText(e));
      }
    } catch (_) {
      if (mounted) Helpers.error(context, AppStrings.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _errorText(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        return 'Incorrect email or password';
      case 'invalid-email':
        return 'Please enter a valid email';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      default:
        return AppStrings.somethingWentWrong;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.go('/login'),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.admin_panel_settings,
                      size: 56, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Admin Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Only authorized administrators can log in here',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Form(
                    key: _form,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            labelText: 'Admin Email',
                            prefixIcon: const Icon(Icons.email_outlined,
                                color: AppColors.textSecondary),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          validator: Validators.password,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline,
                                color: AppColors.textSecondary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          text: 'Login as Admin',
                          isLoading: _loading,
                          onPressed: _login,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text(
                    'Login as Customer instead',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== ADMIN DASHBOARD ====================
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/admin-login');
      });
      return const Scaffold(body: AppLoading());
    }

    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: 'Admin Profile',
              onPressed: () => _showAdminProfileSheet(context),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                final ok = await AppDialog.confirm(
                  context,
                  title: 'Log out?',
                  message: 'You will be logged out of admin panel.',
                  confirmText: 'Log out',
                  isDestructive: true,
                );
                if (ok) {
                  await AuthService.signOut();
                  if (context.mounted) context.go('/login');
                }
              },
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                child: Consumer(
                  builder: (context, ref, _) {
                    final unread = ref.watch(unreadOrdersCountProvider);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Orders'),
                        if (unread > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              const Tab(text: 'Products'),
              const Tab(text: 'Announcements'),
              const Tab(text: 'Promos'),
              const Tab(text: 'Notify'),
              const Tab(text: 'Settings'),
              const Tab(text: 'Users'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OrdersTab(),
            _ProductsTab(),
            _AnnouncementsTab(),
            _PromosTab(),
            _NotifyTab(),
            _SettingsTab(),
            _UsersTab(),
          ],
        ),
      ),
    );
  }

  void _showAdminProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AdminProfileSheet(),
    );
  }
}

// ==================== ADMIN PROFILE SHEET ====================
class _AdminProfileSheet extends ConsumerStatefulWidget {
  const _AdminProfileSheet();
  @override
  ConsumerState<_AdminProfileSheet> createState() =>
      _AdminProfileSheetState();
}

class _AdminProfileSheetState extends ConsumerState<_AdminProfileSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _newEmail = TextEditingController();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();

  bool _savingProfile = false;
  bool _savingEmail = false;
  bool _savingPassword = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).valueOrNull;
    _name.text = profile?.name ?? '';
    _phone.text = profile?.phone ?? '';
    _newEmail.text = ref.read(authStateProvider).valueOrNull?.email ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _newEmail.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    try {
      await AuthService.updateProfile(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
      );
      if (mounted) {
        Helpers.success(context, 'Profile updated');
      }
    } catch (_) {
      if (mounted) Helpers.error(context, AppStrings.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _updateEmail() async {
    final newEmail = _newEmail.text.trim();
    final current = ref.read(authStateProvider).valueOrNull?.email;
    if (newEmail.isEmpty || newEmail == current) {
      Helpers.error(context, 'Please enter a new email');
      return;
    }
    if (Validators.email(newEmail) != null) {
      Helpers.error(context, 'Please enter a valid email');
      return;
    }
    setState(() => _savingEmail = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');
      await user.verifyBeforeUpdateEmail(newEmail);
      if (mounted) {
        Helpers.success(context, 'Verification link sent to $newEmail');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        Helpers.error(context, _authError(e));
      }
    } catch (_) {
      if (mounted) Helpers.error(context, AppStrings.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _savingEmail = false);
    }
  }

  Future<void> _updatePassword() async {
    if (_currentPassword.text.isEmpty || _newPassword.text.isEmpty) {
      Helpers.error(context, 'Please fill both password fields');
      return;
    }
    if (_newPassword.text.length < 6) {
      Helpers.error(context, 'New password must be at least 6 characters');
      return;
    }
    setState(() => _savingPassword = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPassword.text,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPassword.text);
      _currentPassword.clear();
      _newPassword.clear();
      if (mounted) Helpers.success(context, 'Password updated');
    } on FirebaseAuthException catch (e) {
      if (mounted) Helpers.error(context, _authError(e));
    } catch (_) {
      if (mounted) Helpers.error(context, AppStrings.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Current password is incorrect';
      case 'email-already-in-use':
        return 'This email is already in use';
      case 'requires-recent-login':
        return 'Please login again to change this';
      case 'invalid-email':
        return 'Please enter a valid email';
      default:
        return e.message ?? AppStrings.somethingWentWrong;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.9;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Admin Profile', style: AppTextStyles.heading),
            const SizedBox(height: 20),

            const Text('Profile Information',
                style: AppTextStyles.headingSmall),
            const SizedBox(height: 10),
            AppTextField(label: 'Name', controller: _name),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Phone',
              controller: _phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Save Profile',
              isLoading: _savingProfile,
              onPressed: _saveProfile,
            ),

            const Divider(height: 40),

            const Text('Change Email', style: AppTextStyles.headingSmall),
            const SizedBox(height: 4),
            Text(
              'A verification link will be sent to the new email.',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'New Email',
              controller: _newEmail,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Update Email',
              isLoading: _savingEmail,
              onPressed: _updateEmail,
            ),

            const Divider(height: 40),

            const Text('Change Password', style: AppTextStyles.headingSmall),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Current Password',
              controller: _currentPassword,
              isPassword: true,
              prefixIcon: Icons.lock_outline,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'New Password (min 6 chars)',
              controller: _newPassword,
              isPassword: true,
              prefixIcon: Icons.lock_outline,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Update Password',
              isLoading: _savingPassword,
              onPressed: _updatePassword,
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ==================== ORDERS TAB ====================
class _OrdersTab extends ConsumerStatefulWidget {
  const _OrdersTab();
  @override
  ConsumerState<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends ConsumerState<_OrdersTab> {
  bool _onlyActive = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final orders = ref.read(allOrdersProvider).valueOrNull ?? [];
      final notifier = ref.read(adminViewedOrdersProvider.notifier);
      final activeIds = orders
          .where((o) =>
              o.status != 'delivered' && o.status != 'cancelled')
          .map((o) => o.id)
          .toList();
      notifier.markAllViewed(activeIds);
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(allOrdersProvider);
    return async.when(
      loading: () => const AppLoading(),
      error: (e, _) {
        debugPrint('Orders error: $e');
        return const AppEmpty(
          title: 'No orders yet',
          message: 'New orders will appear here',
          icon: Icons.receipt_long_outlined,
        );
      },
      data: (all) {
        final now = DateTime.now();
        final today = all.where((o) =>
            o.createdAt.year == now.year &&
            o.createdAt.month == now.month &&
            o.createdAt.day == now.day &&
            o.status != 'cancelled');
        final sales = today.fold<double>(0, (s, o) => s + o.total);
        final list = _onlyActive
            ? all
                .where((o) =>
                    o.status != 'delivered' && o.status != 'cancelled')
                .toList()
            : all;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.p12),
              child: Row(
                children: [
                  Expanded(
                      child: _Stat("Today's orders", '${today.length}',
                          Icons.receipt_long)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _Stat("Today's sales",
                          Formatters.price(sales), Icons.payments)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
              child: Row(
                children: [
                  ChoiceChip(
                      label: const Text('Active'),
                      selected: _onlyActive,
                      onSelected: (_) =>
                          setState(() => _onlyActive = true)),
                  const SizedBox(width: 8),
                  ChoiceChip(
                      label: const Text('All'),
                      selected: !_onlyActive,
                      onSelected: (_) =>
                          setState(() => _onlyActive = false)),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const AppEmpty(title: 'No orders yet')
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSizes.p12),
                      itemCount: list.length,
                      itemBuilder: (_, i) =>
                          _AdminOrderCard(order: list[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Stat(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSizes.p14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.r14),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: AppTextStyles.headingSmall),
                  Text(label, style: AppTextStyles.captionSmall),
                ],
              ),
            ),
          ],
        ),
      );
}

class _AdminOrderCard extends StatelessWidget {
  final OrderModel order;
  const _AdminOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final o = order;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSizes.p14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSizes.r16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('# ${shortOrderId(o.id)}  •  ${o.userName}',
                    style: AppTextStyles.labelBold),
              ),
              PopupMenuButton<String>(
                tooltip: 'Change status',
                onSelected: (s) async {
                  await FirestoreService.updateOrderStatus(o.id, s);
                  if (context.mounted) {
                    Helpers.success(context,
                        'Status: ${Formatters.orderStatus(s)}');
                  }
                },
                itemBuilder: (_) => [
                  for (final s in _statuses)
                    PopupMenuItem(
                        value: s, child: Text(Formatters.orderStatus(s))),
                ],
                child: StatusBadge(
                  status: Formatters.orderStatus(o.status),
                  color: Formatters.orderStatusColor(o.status),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(Formatters.dateTime(o.createdAt),
              style: AppTextStyles.caption),
          const SizedBox(height: 6),
          for (final it in o.items)
            Text(
              '${it.quantity} x ${it.name}'
              '${it.sizeName != null ? " (${it.sizeName})" : ""}'
              '${it.addonNames.isNotEmpty ? " + ${it.addonNames.join(", ")}" : ""}',
              style: AppTextStyles.body,
            ),
          const Divider(),
          Row(
            children: [
              const Icon(Icons.phone, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Phone: ${o.userPhone}',
                    style: AppTextStyles.labelBold
                        .copyWith(color: AppColors.primary)),
              ),
              IconButton(
                icon: const Icon(Icons.call, color: AppColors.success),
                onPressed: () => Helpers.call(o.userPhone),
              ),
            ],
          ),
          Text(
            o.orderType == 'delivery'
                ? 'Delivery: ${o.address?.fullAddress ?? "-"}'
                : 'Pickup',
            style: AppTextStyles.caption,
          ),
          if (o.liveLat != 0 && o.liveLng != 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.my_location,
                    size: 14, color: AppColors.success),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Live: ${o.liveLat.toStringAsFixed(5)}, ${o.liveLng.toStringAsFixed(5)}',
                    style: AppTextStyles.captionSmall
                        .copyWith(color: AppColors.success),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.map,
                      size: 18, color: AppColors.success),
                  onPressed: () => Helpers.openMap(o.liveLat, o.liveLng),
                ),
              ],
            ),
          ],
          if (o.note != null)
            Text('Note: ${o.note}', style: AppTextStyles.caption),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(Formatters.price(o.total),
                    style: AppTextStyles.price
                        .copyWith(color: AppColors.primary)),
              ),
              IconButton(
                icon: const Icon(Icons.chat, color: AppColors.success),
                onPressed: () => Helpers.whatsapp(o.userPhone,
                    message:
                        'Jerry Pizza: your order # ${shortOrderId(o.id)}'),
              ),
            ],
          ),
          if (o.status != 'delivered' && o.status != 'cancelled')
            AppButton(
              text: 'Next step: ${Formatters.orderStatus(_next(o.status))}',
              height: 44,
              onPressed: () =>
                  FirestoreService.updateOrderStatus(o.id, _next(o.status)),
            ),
        ],
      ),
    );
  }

  String _next(String s) {
    final i = _statuses.indexOf(s);
    if (i < 0 || i >= 4) return s;
    return _statuses[i + 1];
  }
}

// ==================== PRODUCTS TAB ====================
class _ProductsTab extends ConsumerWidget {
  const _ProductsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final cats = ref.watch(categoriesProvider);
    final status = ref.watch(menuStatusProvider).valueOrNull ?? {};
    String catName(String id) =>
        cats.where((c) => c.id == id).map((c) => c.name).firstOrNull ?? '';

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showProductDialog(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.p12),
        itemCount: products.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Tap to edit. Use switch to mark item as sold out.',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            );
          }
          final p = products[i - 1];
          final available = status[p.id] ?? p.isAvailable;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              leading: AppImage(
                  imagePath: p.imagePath,
                  width: 52,
                  height: 52,
                  radius: 10),
              title: Text(p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelBold),
              subtitle: Text(
                '${catName(p.categoryId)} · ${Formatters.price(p.basePrice)}',
                style: AppTextStyles.caption,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    activeThumbColor: AppColors.primary,
                    value: available,
                    onChanged: (v) => FirebaseFirestore.instance
                        .collection('menuStatus')
                        .doc(p.id)
                        .set({'available': v}),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'edit') {
                        _showProductDialog(context, ref, p);
                      } else if (action == 'delete') {
                        _confirmDelete(context, p);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              onTap: () => _showProductDialog(context, ref, p),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProductModel p) async {
    final ok = await AppDialog.confirm(
      context,
      title: 'Delete ${p.name}?',
      message: 'This product will be hidden from the app.',
      confirmText: 'Delete',
      isDestructive: true,
    );
    if (ok) {
      await FirebaseFirestore.instance
          .collection('menuStatus')
          .doc(p.id)
          .set({'available': false, 'deleted': true});
      if (context.mounted) {
        Helpers.success(context, '${p.name} deleted');
      }
    }
  }

  void _showProductDialog(
      BuildContext context, WidgetRef ref, ProductModel? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl =
        TextEditingController(text: existing?.description ?? '');
    final priceCtrl = TextEditingController(
        text: existing != null ? existing.basePrice.toStringAsFixed(0) : '');
    final imgCtrl = TextEditingController(text: existing?.imagePath ?? '');
    String categoryId = existing?.categoryId ?? 'best_pizza';
    bool isPopular = existing?.isPopular ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? 'Add Product' : 'Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Base price (Rs)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: imgCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Image path (assets/...)'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: categoryId,
                  decoration:
                      const InputDecoration(labelText: 'Category'),
                  items: [
                    for (final c in ref.read(categoriesProvider))
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) =>
                      setS(() => categoryId = v ?? 'best_pizza'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.primary,
                  title: const Text('Mark as popular'),
                  value: isPopular,
                  onChanged: (v) => setS(() => isPopular = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    priceCtrl.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(ctx);
                Helpers.snack(context,
                    existing == null ? 'Added' : 'Updated');
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== ANNOUNCEMENTS TAB ====================
class _AnnouncementsTab extends ConsumerWidget {
  const _AnnouncementsTab();

  Future<void> _add(BuildContext context) async {
    final title = TextEditingController();
    final message = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: message,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Publish')),
        ],
      ),
    );

    if (ok == true &&
        title.text.trim().isNotEmpty &&
        message.text.trim().isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('announcements').add({
          'title': title.text.trim(),
          'message': message.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (context.mounted) {
          Helpers.success(context, 'Announcement published');
        }
      } catch (e) {
        debugPrint('Publish error: $e');
        if (context.mounted) {
          Helpers.error(context, 'Failed to publish');
        }
      }
    }
    title.dispose();
    message.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(announcementsProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _add(context),
        icon: const Icon(Icons.campaign),
        label: const Text('New Announcement'),
      ),
      body: async.when(
        loading: () => const AppLoading(),
        error: (e, _) {
          debugPrint('Announcements error: $e');
          return const AppEmpty(
            title: 'No announcements yet',
            message: 'Add your first announcement',
            icon: Icons.campaign_outlined,
          );
        },
        data: (list) => list.isEmpty
            ? const AppEmpty(
                title: 'No announcements yet',
                message: 'Add your first announcement',
                icon: Icons.campaign_outlined)
            : ListView.builder(
                padding: const EdgeInsets.all(AppSizes.p12),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final a = list[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.campaign,
                            color: Colors.purple),
                      ),
                      title: Text('${a['title'] ?? ''}',
                          style: AppTextStyles.labelBold),
                      subtitle: Text('${a['message'] ?? ''}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error),
                        onPressed: () async {
                          final ok = await AppDialog.confirm(context,
                              title: 'Delete announcement?',
                              message: 'This cannot be undone.',
                              isDestructive: true);
                          if (ok) {
                            await FirebaseFirestore.instance
                                .collection('announcements')
                                .doc(a['id'])
                                .delete();
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// ==================== PROMOS TAB ====================
class _PromosTab extends ConsumerWidget {
  const _PromosTab();

  Future<void> _add(BuildContext context) async {
    final code = TextEditingController();
    final value = TextEditingController();
    final minOrder = TextEditingController(text: '0');
    final maxDisc = TextEditingController(text: '0');
    String type = 'percent';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('New promo code'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: code,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Code')),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  items: const [
                    DropdownMenuItem(
                        value: 'percent', child: Text('Percent %')),
                    DropdownMenuItem(value: 'flat', child: Text('Flat Rs')),
                  ],
                  onChanged: (v) => setS(() => type = v ?? 'percent'),
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                TextField(
                    controller: value,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Value')),
                TextField(
                    controller: minOrder,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Minimum order')),
                TextField(
                    controller: maxDisc,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Max discount (0 = no limit)')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok == true && code.text.trim().isNotEmpty) {
      await FirestoreService.addPromo(PromoModel(
        id: '',
        code: code.text.trim().toUpperCase(),
        type: type,
        value: double.tryParse(value.text) ?? 0,
        minOrder: double.tryParse(minOrder.text) ?? 0,
        maxDiscount: double.tryParse(maxDisc.text) ?? 0,
      ));
    }
    code.dispose();
    value.dispose();
    minOrder.dispose();
    maxDisc.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(promosProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _add(context),
        child: const Icon(Icons.add),
      ),
      body: async.when(
        loading: () => const AppLoading(),
        error: (e, _) =>
            AppError(onRetry: () => ref.invalidate(promosProvider)),
        data: (list) => list.isEmpty
            ? const AppEmpty(title: 'No promo codes yet')
            : ListView.builder(
                padding: const EdgeInsets.all(AppSizes.p12),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final p = list[i];
                  return Card(
                    child: ListTile(
                      title: Text(p.code, style: AppTextStyles.labelBold),
                      subtitle: Text(
                        '${p.type == "percent" ? "${p.value.toStringAsFixed(0)}%" : Formatters.price(p.value)} off'
                        '  •  Min ${Formatters.price(p.minOrder)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: p.isActive,
                            activeThumbColor: AppColors.primary,
                            onChanged: (v) => FirestoreService.updatePromo(
                              p.id,
                              PromoModel(
                                id: p.id,
                                code: p.code,
                                type: p.type,
                                value: p.value,
                                minOrder: p.minOrder,
                                maxDiscount: p.maxDiscount,
                                expiry: p.expiry,
                                isActive: v,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error),
                            onPressed: () async {
                              final ok = await AppDialog.confirm(context,
                                  title: 'Delete?',
                                  message: '${p.code} will be removed.',
                                  isDestructive: true);
                              if (ok) {
                                await FirestoreService.deletePromo(p.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// ==================== NOTIFY TAB ====================
class _NotifyTab extends StatefulWidget {
  const _NotifyTab();
  @override
  State<_NotifyTab> createState() => _NotifyTabState();
}

class _NotifyTabState extends State<_NotifyTab> {
  final _title = TextEditingController();
  final _msg = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _msg.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_title.text.trim().isEmpty || _msg.text.trim().isEmpty) {
      Helpers.error(context, 'Please enter a title and a message');
      return;
    }
    setState(() => _sending = true);
    try {
      await FirestoreService.sendNotification(
          title: _title.text.trim(), message: _msg.text.trim());
      _title.clear();
      _msg.clear();
      if (mounted) Helpers.success(context, 'Notification sent');
    } catch (_) {
      if (mounted) Helpers.error(context, AppStrings.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.p16),
      children: [
        Text(
          'This message appears on every customer\'s Notifications screen.',
          style: AppTextStyles.caption
              .copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        AppTextField(label: 'Title', controller: _title),
        const SizedBox(height: 12),
        AppTextField(
            label: 'Message',
            controller: _msg,
            maxLines: 3,
            textInputAction: TextInputAction.done),
        const SizedBox(height: 16),
        AppButton(text: 'Send', isLoading: _sending, onPressed: _send),
      ],
    );
  }
}

// ==================== SETTINGS TAB ====================
class _SettingsTab extends ConsumerStatefulWidget {
  const _SettingsTab();
  @override
  ConsumerState<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<_SettingsTab> {
  bool _loaded = false;
  bool _saving = false;
  bool _isOpen = true;
  bool _holiday = false;
  late SettingsModel _base;
  final _fee = TextEditingController();
  final _minOrder = TextEditingController();
  final _free = TextEditingController();
  final _radius = TextEditingController();
  final _contact = TextEditingController();
  final _whatsapp = TextEditingController();
  final _address = TextEditingController();
  final _reason = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();

  void _fill(SettingsModel s) {
    _base = s;
    _isOpen = s.isOpen;
    _holiday = s.holidayMode;
    _fee.text = s.deliveryFee.toStringAsFixed(0);
    _minOrder.text = s.minOrder.toStringAsFixed(0);
    _free.text = s.freeDelivery.toStringAsFixed(0);
    _radius.text = s.deliveryRadiusKm.toString();
    _contact.text = s.contactNumber;
    _whatsapp.text = s.whatsappNumber;
    _address.text = s.restaurantAddress;
    _reason.text = s.holidayReason;
    _lat.text = s.restaurantLat.toString();
    _lng.text = s.restaurantLng.toString();
    _loaded = true;
  }

  @override
  void dispose() {
    for (final c in [
      _fee,
      _minOrder,
      _free,
      _radius,
      _contact,
      _whatsapp,
      _address,
      _reason,
      _lat,
      _lng,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await FirestoreService.updateSettings(SettingsModel(
        deliveryFee: double.tryParse(_fee.text) ?? _base.deliveryFee,
        minOrder: double.tryParse(_minOrder.text) ?? _base.minOrder,
        freeDelivery: double.tryParse(_free.text) ?? _base.freeDelivery,
        isOpen: _isOpen,
        contactNumber: _contact.text.trim(),
        whatsappNumber: _whatsapp.text.trim(),
        restaurantAddress: _address.text.trim(),
        deliveryRadiusKm:
            double.tryParse(_radius.text) ?? _base.deliveryRadiusKm,
        restaurantLat: double.tryParse(_lat.text) ?? _base.restaurantLat,
        restaurantLng: double.tryParse(_lng.text) ?? _base.restaurantLng,
        holidayMode: _holiday,
        holidayReason: _reason.text.trim(),
      ));
      if (mounted) Helpers.success(context, 'Settings saved');
    } catch (_) {
      if (mounted) Helpers.error(context, AppStrings.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(settingsProvider);
    if (!_loaded && async.hasValue) _fill(async.value!);
    if (!_loaded) return const AppLoading();

    return ListView(
      padding: const EdgeInsets.all(AppSizes.p16),
      children: [
        SwitchListTile(
          title: const Text('Restaurant is open'),
          value: _isOpen,
          activeThumbColor: AppColors.primary,
          onChanged: (v) => setState(() => _isOpen = v),
        ),
        SwitchListTile(
          title: const Text('Holiday mode'),
          value: _holiday,
          activeThumbColor: AppColors.primary,
          onChanged: (v) => setState(() => _holiday = v),
        ),
        AppTextField(label: 'Holiday message', controller: _reason),
        const SizedBox(height: 12),
        AppTextField(
            label: 'Delivery fee (Rs)',
            controller: _fee,
            keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        AppTextField(
            label: 'Minimum order (Rs) - 0 to disable',
            controller: _minOrder,
            keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        AppTextField(
            label: 'Free delivery above (Rs)',
            controller: _free,
            keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        AppTextField(
            label: 'Delivery radius (km)',
            controller: _radius,
            keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        AppTextField(
            label: 'Restaurant latitude',
            controller: _lat,
            keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        AppTextField(
            label: 'Restaurant longitude',
            controller: _lng,
            keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        AppTextField(label: 'Contact number', controller: _contact),
        const SizedBox(height: 12),
        AppTextField(label: 'WhatsApp number', controller: _whatsapp),
        const SizedBox(height: 12),
        AppTextField(
            label: 'Restaurant address',
            controller: _address,
            textInputAction: TextInputAction.done),
        const SizedBox(height: 20),
        AppButton(text: 'Save Settings', isLoading: _saving, onPressed: _save),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ==================== USERS TAB ====================
class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(usersProvider);
    return async.when(
      loading: () => const AppLoading(),
      error: (e, _) {
        debugPrint('Users error: $e');
        return const AppEmpty(
          title: 'No users yet',
          message: 'Registered users will appear here',
          icon: Icons.people_outline,
        );
      },
      data: (list) => ListView.separated(
        padding: const EdgeInsets.all(AppSizes.p12),
        itemCount: list.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final u = list[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(u.name.isEmpty ? '?' : u.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white)),
            ),
            title: Text(u.name),
            subtitle: Text('${u.email}\n${u.phone}'),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.call, color: AppColors.success),
              onPressed: () => Helpers.call(u.phone),
            ),
          );
        },
      ),
    );
  }
}