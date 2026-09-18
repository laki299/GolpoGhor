import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/theme/app_colors.dart';

class DraftsScreen extends StatefulWidget {
  const DraftsScreen({super.key});

  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  final _storyService = StoryService();
  List<StoryModel> _drafts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final drafts = await _storyService.getDrafts();
      setState(() {
        _drafts = drafts;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _publish(String storyId) async {
    try {
      await _storyService.publishDraft(storyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('খসড়া প্রকাশিত হয়েছে')),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('সমস্যা: $e')),
        );
      }
    }
  }

  Future<void> _delete(String storyId) async {
    try {
      await _storyService.deleteStory(storyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('খসড়া মুছে ফেলা হয়েছে')),
        );
      }
      _load();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('খসড়া'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _drafts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.drafts_outlined,
                        size: 56,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'কোনো খসড়া নেই',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _drafts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final draft = _drafts[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            draft.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            draft.previewText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                context.push('/edit-story/${draft.id}');
                              } else if (value == 'publish') {
                                _publish(draft.id);
                              } else if (value == 'delete') {
                                _delete(draft.id);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('এডিট'),
                              ),
                              PopupMenuItem(
                                value: 'publish',
                                child: Text('প্রকাশ করুন'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('মুছুন'),
                              ),
                            ],
                          ),
                          onTap: () => context.push('/edit-story/${draft.id}'),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
