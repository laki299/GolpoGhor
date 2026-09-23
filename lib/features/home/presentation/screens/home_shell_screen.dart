import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/media_service.dart';
import '../../../../core/theme/app_colors.dart';
import 'home_feed_screen.dart';
import 'audio_feed_screen.dart';
import 'video_feed_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen>
    with SingleTickerProviderStateMixin {
  final _media = MediaService();
  bool _loading = true;
  bool _audioOn = false;
  bool _videoOn = false;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _loadFlags();
  }

  Future<void> _loadFlags() async {
    final a = await _media.isAudioFeedEnabled();
    final v = await _media.isVideoFeedEnabled();
    final count = 1 + (a ? 1 : 0) + (v ? 1 : 0);
    _tabController?.dispose();
    _tabController = TabController(length: count, vsync: this);
    setState(() {
      _audioOn = a;
      _videoOn = v;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _tabController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final tabs = <Tab>[
      const Tab(text: 'গল্প'),
      if (_audioOn) const Tab(text: 'অডিও'),
      if (_videoOn) const Tab(text: 'ভিডিও'),
    ];

    final views = <Widget>[
      const HomeFeedScreen(embedded: true),
      if (_audioOn) const AudioFeedScreen(),
      if (_videoOn) const VideoFeedScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('গল্পঘর'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
        bottom: tabs.length > 1
            ? TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                indicatorColor: AppColors.primary,
                tabs: tabs,
              )
            : null,
      ),
      body: tabs.length > 1
          ? TabBarView(
              controller: _tabController,
              children: views,
            )
          : views.first,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-story'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}
