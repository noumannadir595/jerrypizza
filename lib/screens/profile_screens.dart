import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config.dart';
import '../models.dart';
import '../providers.dart';
import '../services.dart';
import '../widgets.dart';

// ==================== PROFILE ====================
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final isAdmin = ref.watch(isAdminProvider);
    final dark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final settings = ref.watch(settingsProvider).valueOrNull ?? SettingsModel();
    final orders = ref.watch(myOrdersProvider).valueOrNull ?? [];
    final favCount = ref.watch(favoriteIdsProvider).valueOrNull?.length ?? 0;

    final name = (profile?.name ?? user?.displayName ?? '').trim();

    Widget tile(IconData icon, String title, VoidCallback onTap,
            {Widget? trailing, Color? color}) =>
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color ?? AppColors.primary, size: 20),
          ),
          title: Text(title, style: TextStyle(color: color)),
          trailing: trailing ?? const Icon(Icons.chevron_right),
          onTap: onTap,
        );

    Widget group(List<Widget> children) => Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: softShadow(),
          ),
          child: Column(children: children),
        );

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 20, 20, 28),
            margin: const EdgeInsets.only(bottom: 18),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: user == null
                ? Column(
                    children: [
                      const CircleAvatar(
                        radius: 38,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person, size: 42, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      const Text('Welcome, guest',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      const Text('Log in to track orders and save addresses',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary),
                              onPressed: () => context.push('/login'),
                              child: const Text('Log in'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white)),
                              onPressed: () => context.push('/signup'),
                              child: const Text('Sign up'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: Colors.white,
                            child: Text(
                              name.isEmpty ? 'U' : name[0].toUpperCase(),
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name.isEmpty ? 'Customer' : name,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700)),
                                Text(user.email ?? '',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13)),
                                if ((profile?.phone ?? '').isNotEmpty)
                                  Text(profile!.phone,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _Stat('${orders.length}', 'Orders'),
                          _Stat('$favCount', 'Favorites'),
                          _Stat(
                              '${orders.where((o) => o.status == "delivered").length}',
                              'Delivered'),
                        ],
                      ),
                    ],
                  ),
          ).animate().fadeIn(),
          if (user != null)
            group([
              tile(Icons.person_outline, 'Edit profile',
                  () => context.push('/edit-profile')),
              tile(Icons.location_on_outlined, 'My addresses',
                  () => context.push('/addresses')),
              tile(Icons.favorite_border, 'Favorites',
                  () => context.push('/favorites')),
            ]),
          group([
            tile(Icons.notifications_none, 'Notifications',
                () => context.push('/notifications')),
            tile(
              Icons.dark_mode_outlined,
              'Dark mode',
              () {},
              trailing: Switch(
                value: dark,
                activeThumbColor: AppColors.primary,
                onChanged: (v) =>
                    ref.read(themeModeProvider.notifier).setDark(v),
              ),
            ),
          ]),
          group([
            tile(Icons.help_outline, 'Help & FAQ', () => context.push('/help')),
            tile(Icons.chat_bubble_outline, 'Chat on WhatsApp',
                () => Helpers.whatsapp(settings.whatsappNumber,
                    message: 'Hello, I need some help.')),
            tile(Icons.call_outlined, 'Call us',
                () => Helpers.call(settings.contactNumber)),
          ]),
          group([
            tile(Icons.description_outlined, 'Terms & Conditions',
                () => context.push('/legal/terms')),
            tile(Icons.privacy_tip_outlined, 'Privacy Policy',
                () => context.push('/legal/privacy')),
            tile(Icons.info_outline, 'About', () => context.push('/about')),
          ]),
          if (isAdmin)
            group([
              tile(Icons.admin_panel_settings_outlined, 'Admin Panel',
                  () => context.push('/admin')),
            ]),
          if (user != null)
            group([
              tile(Icons.logout, 'Log out', () async {
                final ok = await AppDialog.confirm(context,
                    title: 'Log out?',
                    message: 'Are you sure you want to log out?',
                    confirmText: 'Log out',
                    isDestructive: true);
                if (ok) await AuthService.signOut();
              }, color: AppColors.error, trailing: const SizedBox.shrink()),
            ]),
          const SizedBox(height: 8),
          Center(
            child: Column(
              children: [
                Text('Version 1.0.0',
                    style: AppTextStyles.captionSmall.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    )),
                const SizedBox(height: 4),
                Text(
                  'Developed by Nouman Nadir',
                  style: AppTextStyles.captionSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'noumannadir595@gmail.com',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      );
}

// ==================== EDIT PROFILE ====================
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(userProfileProvider).valueOrNull;
    _name = TextEditingController(text: p?.name ?? '');
    _phone = TextEditingController(text: p?.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.updateProfile(
          name: _name.text.trim(), phone: _phone.text.trim());
      if (!mounted) return;
      Helpers.success(context, 'Profile updated');
      context.pop();
    } catch (_) {
      if (mounted) Helpers.error(context, AppStrings.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            children: [
              AppTextField(
                  label: 'Full name',
                  controller: _name,
                  prefixIcon: Icons.person_outline,
                  validator: Validators.name),
              const SizedBox(height: 16),
              AppTextField(
                  label: 'Phone number',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: Validators.phone,
                  textInputAction: TextInputAction.done),
              const SizedBox(height: 24),
              AppButton(text: 'Save', isLoading: _loading, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== ADDRESSES ====================
class AddressListScreen extends ConsumerWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(addressesProvider);
    final uid = AuthService.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('My addresses')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/location'),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add address'),
      ),
      body: async.when(
        loading: () => const AppLoading(),
        error: (e, _) =>
            AppError(onRetry: () => ref.invalidate(addressesProvider)),
        data: (list) => list.isEmpty
            ? AppEmpty(
                title: 'No saved addresses',
                message: 'Pin your location on the map to get started',
                icon: Icons.location_off_outlined,
                buttonText: 'Pick on map',
                onButtonPressed: () => context.push('/location'),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final a = list[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: softShadow(),
                      border: a.isDefault
                          ? Border.all(color: AppColors.primary, width: 1.5)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                                a.label == 'Work'
                                    ? Icons.work_outline
                                    : a.label == 'Home'
                                        ? Icons.home_outlined
                                        : Icons.place_outlined,
                                color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(a.label, style: AppTextStyles.labelBold),
                            if (a.isDefault) ...[
                              const SizedBox(width: 8),
                              const Chip(
                                  label: Text('Default'),
                                  visualDensity: VisualDensity.compact),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(a.fullAddress),
                        if (a.landmark != null && a.landmark!.isNotEmpty)
                          Text('Landmark: ${a.landmark}',
                              style: AppTextStyles.caption),
                        Text(a.phone, style: AppTextStyles.caption),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!a.isDefault && uid != null)
                              TextButton(
                                onPressed: () =>
                                    FirestoreService.setDefaultAddress(uid, a.id),
                                child: const Text('Set as default'),
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () =>
                                  context.push('/location', extra: a),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.error),
                              onPressed: () async {
                                if (uid == null) return;
                                final ok = await AppDialog.confirm(context,
                                    title: 'Delete address?',
                                    message: 'This address will be removed.',
                                    confirmText: 'Delete',
                                    isDestructive: true);
                                if (ok) {
                                  await FirestoreService.deleteAddress(uid, a.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate(delay: (40 * i).ms).fadeIn().slideY(begin: 0.08, end: 0);
                },
              ),
      ),
    );
  }
}

// ==================== FAVORITES ====================
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(favoriteProductsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: list.isEmpty
          ? const AppEmpty(
              title: 'No favorites yet',
              message: 'Tap the heart on any item to save it here',
              icon: Icons.favorite_border)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) => ProductTile(
                  product: list[i], heroTag: 'fav_${list[i].id}', index: i),
            ),
    );
  }
}

// ==================== NOTIFICATIONS ====================
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: async.when(
        loading: () => const AppLoading(),
        error: (e, _) =>
            AppError(onRetry: () => ref.invalidate(notificationsProvider)),
        data: (list) => list.isEmpty
            ? const AppEmpty(
                title: 'No notifications',
                message: 'Offers and updates will appear here',
                icon: Icons.notifications_none)
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (_, i) {
                  final n = list[i];
                  final ts = n['sentAt'];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.notifications, color: Colors.white),
                    ),
                    title: Text('${n['title'] ?? ''}',
                        style: AppTextStyles.labelBold),
                    subtitle: Text('${n['message'] ?? ''}'),
                    trailing: ts is Timestamp
                        ? Text(Formatters.timeAgo(ts.toDate()),
                            style: AppTextStyles.captionSmall)
                        : null,
                  );
                },
              ),
      ),
    );
  }
}

// ==================== HELP & FAQ ====================
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    ('How long does delivery take?',
        'Most orders arrive within 30 to 45 minutes, depending on distance and how busy the kitchen is.'),
    ('What payment methods do you accept?',
        'Right now we accept Cash on Delivery. Please keep the exact amount ready if possible.'),
    ('Can I cancel my order?',
        'Please call us directly to discuss cancellation.'),
    ('Is there a minimum order?',
        'Yes, a minimum order amount applies. You will see it in your cart and at checkout.'),
    ('Where do you deliver?',
        'We deliver within a few kilometers of the restaurant. Drop your pin on the map and the app will tell you if you are inside the area.'),
    ('My order is late or wrong. What should I do?',
        'Call or message us on WhatsApp from the order screen and we will sort it out right away.'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider).valueOrNull ?? SettingsModel();
    return Scaffold(
      appBar: AppBar(title: const Text('Help & FAQ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Helpers.call(s.contactNumber),
                  icon: const Icon(Icons.call),
                  label: const Text('Call us'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success),
                  onPressed: () => Helpers.whatsapp(s.whatsappNumber,
                      message: 'Hello, I need some help.'),
                  icon: const Icon(Icons.chat),
                  label: const Text('WhatsApp'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Frequently asked questions',
              style: AppTextStyles.headingSmall),
          const SizedBox(height: 10),
          for (final f in _faqs)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(f.$1, style: AppTextStyles.labelBold),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(f.$2, style: AppTextStyles.body)],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ==================== LEGAL ====================
class LegalScreen extends StatelessWidget {
  final String type;
  const LegalScreen({super.key, required this.type});

  static const _terms = [
    ('1. Using the app',
        'By placing an order you confirm that the details you provide (name, phone number and address) are correct.'),
    ('2. Orders and pricing',
        'Prices shown in the app are in Pakistani Rupees and may change without notice. The total at checkout is the final amount payable.'),
    ('3. Delivery',
        'Delivery times are estimates. We deliver only within our service area and may refuse orders outside it.'),
    ('4. Cancellations',
        'You can cancel an order by calling us directly. Once preparation starts, cancellation is at our discretion.'),
    ('5. Payment',
        'Payment is currently Cash on Delivery. Please pay the rider the exact order total.'),
    ('6. Changes',
        'We may update these terms from time to time. Continued use of the app means you accept the updated terms.'),
  ];

  static const _privacy = [
    ('Information we collect',
        'We collect your name, phone number, email address, delivery addresses (including the map location you choose) and your order history.'),
    ('How we use it',
        'We use this information only to take and deliver your orders, contact you about them and improve our service.'),
    ('Location',
        'Your location is used only when you choose to pin a delivery address or tap "My location". We do not track you in the background.'),
    ('Sharing',
        'We do not sell your data. Your name, phone number and address are shared only with the staff who prepare and deliver your order.'),
    ('Storage and security',
        'Your data is stored securely using Google Firebase. You can ask us to delete your account and data at any time.'),
    ('Contact',
        'For any privacy questions, call or message us using the details in the About screen.'),
  ];

  @override
  Widget build(BuildContext context) {
    final isTerms = type == 'terms';
    final sections = isTerms ? _terms : _privacy;
    return Scaffold(
      appBar: AppBar(
          title: Text(isTerms ? 'Terms & Conditions' : 'Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final s in sections) ...[
            Text(s.$1, style: AppTextStyles.headingSmall),
            const SizedBox(height: 6),
            Text(s.$2,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 18),
          ],
          const Text('Last updated: 2026', style: AppTextStyles.captionSmall),
        ],
      ),
    );
  }
}

// ==================== ABOUT ====================
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider).valueOrNull ?? SettingsModel();
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient, shape: BoxShape.circle),
              child: const Icon(Icons.local_pizza, size: 64, color: Colors.white),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
          ),
          const SizedBox(height: 14),
          const Text(AppStrings.appName,
              style: AppTextStyles.heading, textAlign: TextAlign.center),
          const Text(AppStrings.appTagline,
              textAlign: TextAlign.center, style: AppTextStyles.body),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.location_on, color: AppColors.primary),
            title: Text(s.restaurantAddress),
          ),
          ListTile(
            leading: const Icon(Icons.call, color: AppColors.primary),
            title: Text(s.contactNumber),
            onTap: () => Helpers.call(s.contactNumber),
          ),
          ListTile(
            leading: const Icon(Icons.chat, color: AppColors.primary),
            title: const Text('WhatsApp'),
            subtitle: Text(s.whatsappNumber),
            onTap: () => Helpers.whatsapp(s.whatsappNumber),
          ),
          const SizedBox(height: 20),
          const Text('Version 1.0.0',
              textAlign: TextAlign.center, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}