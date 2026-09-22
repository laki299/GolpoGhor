import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/follow_service.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/theme/app_colors.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _authService = AuthService();
  final _followService = FollowService();
  final _adminService = AdminService();

  UserModel? _profile;
  bool _isLoading = true;
  bool _isAdmin = false;
  int _followerCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _authService.getCurrentProfile();
    final admin = await _adminService.isCurrentUserAdmin();
    if (profile != null) {
      final followers = await _followService.getFollowerCount(profile.id);
      final following = await _followService.getFollowingCount(profile.id);
      setState(() {
        _profile = profile;
        _isAdmin = admin;
        _followerCount = followers;
        _followingCount = following;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isAdmin = admin;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('প্রোফাইল'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('প্রোফাইল লোড করা যায়নি'))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: AppColors.primary.withOpacity(0.15),
                            backgroundImage: _profile!.avatarUrl != null
                                ? CachedNetworkImageProvider(_profile!.avatarUrl!)
                                : null,
                            child: _profile!.avatarUrl == null
                                ? Text(
                                    (_profile!.fullName ?? 'U')[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _profile!.fullName ?? 'নাম নেই',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          if (_profile!.username != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '@${_profile!.username}',
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            '${_profile!.coins} কয়েন',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _CountItem(count: _followerCount, label: 'ফলোয়ার'),
                              const SizedBox(width: 32),
                              _CountItem(count: _followingCount, label: 'ফলোইং'),
                            ],
                          ),
                          if (_profile!.bio != null &&
                              _profile!.bio!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              _profile!.bio!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _ProfileMenuItem(
                      icon: Icons.edit_outlined,
                      title: 'প্রোফাইল এডিট করুন',
                      onTap: () async {
                        final updated = await context.push('/edit-profile');
                        if (updated == true) _loadProfile();
                      },
                    ),
                    _ProfileMenuItem(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'ওয়ালেট / কয়েন আয়',
                      onTap: () => context.push('/wallet'),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.insights_outlined,
                      title: 'লেখক আয়',
                      onTap: () => context.push('/writer-earnings'),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.library_books_outlined,
                      title: 'আমার লেখা',
                      onTap: () => context.push('/my-works'),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.drafts_outlined,
                      title: 'খসড়া',
                      onTap: () => context.push('/drafts'),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.bookmark_outline,
                      title: 'সংরক্ষিত গল্প',
                      onTap: () => context.push('/saved'),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.download_outlined,
                      title: 'ডাউনলোড করা কনটেন্ট',
                      onTap: () => context.push('/offline'),
                    ),
                    if (_isAdmin)
                      _ProfileMenuItem(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'অ্যাডমিন প্যানেল',
                        onTap: () => context.push('/admin'),
                      ),
                    const Divider(height: 32),
                    _ProfileMenuItem(
                      icon: Icons.logout,
                      title: 'লগআউট',
                      isDestructive: true,
                      onTap: _logout,
                    ),
                  ],
                ),
    );
  }
}

class _CountItem extends StatelessWidget {
  final int count;
  final String label;

  const _CountItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDestructive
        ? AppColors.error
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      trailing: isDestructive
          ? null
          : Icon(
              Icons.chevron_right,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
      onTap: onTap,
    );
  }
}
