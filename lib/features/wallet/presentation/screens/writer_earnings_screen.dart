import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/writer_earnings_service.dart';
import '../../../../core/theme/app_colors.dart';

class WriterEarningsScreen extends StatefulWidget {
  const WriterEarningsScreen({super.key});

  @override
  State<WriterEarningsScreen> createState() => _WriterEarningsScreenState();
}

class _WriterEarningsScreenState extends State<WriterEarningsScreen> {
  final _service = WriterEarningsService();
  bool _loading = true;
  WriterEarningsSummary? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final s = await _service.getMyEarnings();
    setState(() {
      _summary = s;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('লেখক আয়'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'মোট অর্জিত কয়েন',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_summary?.totalCoins ?? 0}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'আনলক থেকে (গল্প/পর্ব)',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => context.push('/withdraw'),
                            icon: const Icon(Icons.payments_outlined),
                            label: const Text('উইথড্র রিকোয়েস্ট'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _PeriodCard(
                          label: '৭ দিন',
                          value: _summary?.days7 ?? 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PeriodCard(
                          label: '১৫ দিন',
                          value: _summary?.days15 ?? 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PeriodCard(
                          label: '৩০ দিন',
                          value: _summary?.days30 ?? 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'কনটেন্ট অনুযায়ী',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_summary == null || _summary!.byContent.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'এখনো কোনো আয় নেই\n(আনলক হলে এখানে দেখাবে)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._summary!.byContent.map((c) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            c.kind == 'story'
                                ? Icons.menu_book_outlined
                                : Icons.auto_stories_outlined,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            c.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${c.kind == 'story' ? 'গল্প' : 'পর্ব'} • ${c.unlockCount} আনলক',
                          ),
                          trailing: Text(
                            '+${c.coins}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  Text(
                    'নোট: টাকা উইথড্র আলাদাভাবে অ্যাডমিন অনুমোদন করবে। '
                    'এখানে শুধু কয়েন হিসাব।',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final String label;
  final int value;

  const _PeriodCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
