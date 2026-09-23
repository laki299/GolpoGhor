import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/services/monetization_service.dart';
import '../../../../core/services/withdraw_service.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/models/novel_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/theme/app_colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _adminService = AdminService();
  final _monetization = MonetizationService();
  final _withdrawService = WithdrawService();
  late TabController _tabController;

  bool _isLoading = true;
  bool _isAdmin = false;
  bool _monetizationOn = false;
  Map<String, int> _stats = {};
  List<StoryModel> _stories = [];
  List<NovelModel> _novels = [];
  List<UserModel> _users = [];
  List<Map<String, dynamic>> _withdraws = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final admin = await _adminService.isCurrentUserAdmin();
    if (!admin) {
      setState(() {
        _isAdmin = false;
        _isLoading = false;
      });
      return;
    }

    final mono = await _monetization.isMonetizationEnabled();
    final stats = await _adminService.getStats();
    final stories = await _adminService.getAllStories();
    final novels = await _adminService.getAllNovels();
    final users = await _adminService.getAllUsers();
    final withdraws = await _withdrawService.getPendingForAdmin();

    setState(() {
      _isAdmin = true;
      _monetizationOn = mono;
      _stats = stats;
      _stories = stories;
      _novels = novels;
      _users = users;
      _withdraws = withdraws;
      _isLoading = false;
    });
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await _init();
  }

  Future<void> _toggleMonetization(bool value) async {
    try {
      await _monetization.setMonetizationEnabled(value);
      setState(() => _monetizationOn = value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'মনিটাইজেশন চালু — অ্যাড ও কয়েন সক্রিয়'
                  : 'মনিটাইজেশন বন্ধ — সব ফ্রি, ডেটা সেভ আছে',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('টগল ব্যর্থ: $e')),
        );
      }
    }
  }

  Future<void> _handleWithdraw(String id, String status) async {
    try {
      await _withdrawService.updateStatus(id: id, status: status);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'approved'
                  ? 'অনুমোদিত'
                  : status == 'paid'
                      ? 'পেমেন্ট সম্পন্ন'
                      : 'বাতিল করা হয়েছে',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('সমস্যা: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('অ্যাডমিন')),
        body: const Center(child: Text('অ্যাডমিন অ্যাক্সেস নেই')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('অ্যাডমিন প্যানেল'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            const Tab(text: 'ড্যাশবোর্ড'),
            const Tab(text: 'গল্প'),
            const Tab(text: 'উপন্যাস'),
            const Tab(text: 'ইউজার'),
            Tab(
              text: _withdraws.isEmpty
                  ? 'উইথড্র'
                  : 'উইথড্র (${_withdraws.length})',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboard(isDark),
          _buildStories(),
          _buildNovels(),
          _buildUsers(),
          _buildWithdraws(isDark),
        ],
      ),
    );
  }

  Widget _buildDashboard(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('মনিটাইজেশন'),
          subtitle: Text(
            _monetizationOn
                ? 'চালু — বিজ্ঞাপন ও কয়েন সক্রিয়'
                : 'বন্ধ — কনটেন্ট ফ্রি, পুরনো ডেটা সেভ',
          ),
          value: _monetizationOn,
          activeColor: AppColors.primary,
          onChanged: _toggleMonetization,
        ),
        const Divider(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(title: 'ইউজার', value: '${_stats['users'] ?? 0}'),
            _StatCard(title: 'গল্প', value: '${_stats['stories'] ?? 0}'),
            _StatCard(title: 'খসড়া', value: '${_stats['drafts'] ?? 0}'),
            _StatCard(title: 'উপন্যাস', value: '${_stats['novels'] ?? 0}'),
            _StatCard(title: 'কমেন্ট', value: '${_stats['comments'] ?? 0}'),
            _StatCard(
              title: 'উইথড্র পেন্ডিং',
              value: '${_withdraws.length}',
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'মডারেশন: গল্প/উপন্যাস ট্যাব থেকে আনপাবলিশ বা ডিলিট।\n'
          'উইথড্র ট্যাব থেকে লেখকের রিকোয়েস্ট অনুমোদন/বাতিল।',
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

  Widget _buildWithdraws(bool isDark) {
    if (_withdraws.isEmpty) {
      return const Center(child: Text('কোনো পেন্ডিং উইথড্র নেই'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _withdraws.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final w = _withdraws[index];
        final profile = w['profiles'];
        final name = profile is Map
            ? (profile['full_name'] ?? profile['username'] ?? 'ইউজার')
            : 'ইউজার';
        final coins = w['coins'];
        final id = w['id'] as String;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$coins কয়েন',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _handleWithdraw(id, 'approved'),
                      child: const Text('অনুমোদন'),
                    ),
                    TextButton(
                      onPressed: () => _handleWithdraw(id, 'paid'),
                      child: const Text('পেড'),
                    ),
                    TextButton(
                      onPressed: () => _handleWithdraw(id, 'rejected'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('বাতিল'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStories() {
    if (_stories.isEmpty) {
      return const Center(child: Text('কোনো গল্প নেই'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _stories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final s = _stories[index];
        return Card(
          child: ListTile(
            title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${s.authorName ?? "অজানা"} • ${s.isPublished ? "প্রকাশিত" : "খসড়া"}',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'unpublish') {
                  await _adminService.unpublishStory(s.id);
                  _refresh();
                } else if (v == 'delete') {
                  await _adminService.deleteStory(s.id);
                  _refresh();
                } else if (v == 'view') {
                  context.push('/story/${s.id}');
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'view', child: Text('দেখুন')),
                PopupMenuItem(value: 'unpublish', child: Text('আনপাবলিশ')),
                PopupMenuItem(value: 'delete', child: Text('ডিলিট')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNovels() {
    if (_novels.isEmpty) {
      return const Center(child: Text('কোনো উপন্যাস নেই'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _novels.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final n = _novels[index];
        return Card(
          child: ListTile(
            title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${n.authorName ?? "অজানা"} • ${n.episodeCount} পর্ব'),
            trailing: PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'unpublish') {
                  await _adminService.unpublishNovel(n.id);
                  _refresh();
                } else if (v == 'delete') {
                  await _adminService.deleteNovel(n.id);
                  _refresh();
                } else if (v == 'view') {
                  context.push('/novel/${n.id}');
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'view', child: Text('দেখুন')),
                PopupMenuItem(value: 'unpublish', child: Text('আনপাবলিশ')),
                PopupMenuItem(value: 'delete', child: Text('ডিলিট')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUsers() {
    if (_users.isEmpty) {
      return const Center(child: Text('কোনো ইউজার নেই'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final u = _users[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: Text(
                (u.fullName ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(u.fullName ?? 'নাম নেই'),
            subtitle: Text(
              '\( {u.username != null ? "@ \){u.username}" : u.id} • ${u.coins} কয়েন',
            ),
            trailing: u.isAdmin
                ? const Chip(
                    label: Text('Admin', style: TextStyle(fontSize: 11)),
                    padding: EdgeInsets.zero,
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
