import 'package:flutter/material.dart';
import '../../../../core/services/withdraw_service.dart';
import '../../../../core/services/writer_earnings_service.dart';
import '../../../../core/theme/app_colors.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _withdrawService = WithdrawService();
  final _earningsService = WriterEarningsService();
  final _controller = TextEditingController();

  bool _loading = true;
  int _minCoins = 5000;
  int _earnedCoins = 0;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final min = await _withdrawService.getMinWithdrawCoins();
    final earnings = await _earningsService.getMyEarnings();
    final reqs = await _withdrawService.getMyRequests();
    setState(() {
      _minCoins = min;
      _earnedCoins = earnings.totalCoins;
      _requests = reqs;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    final coins = int.tryParse(_controller.text.trim());
    if (coins == null || coins <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সঠিক সংখ্যা লিখুন')),
      );
      return;
    }
    try {
      await _withdrawService.createRequest(coins);
      _controller.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('রিকোয়েস্ট পাঠানো হয়েছে')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  String _statusBn(String? s) {
    switch (s) {
      case 'pending':
        return 'অপেক্ষমাণ';
      case 'approved':
        return 'অনুমোদিত';
      case 'rejected':
        return 'বাতিল';
      case 'paid':
        return 'পেমেন্ট সম্পন্ন';
      default:
        return s ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('উইথড্র রিকোয়েস্ট')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    title: const Text('আনলক থেকে মোট আয়'),
                    trailing: Text(
                      '$_earnedCoins কয়েন',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'সর্বনিম্ন উইথড্র: $_minCoins কয়েন\n'
                  'অ্যাডমিন অনুমোদনের পর টাকা আলাদাভাবে দেওয়া হবে।',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'কয়েন সংখ্যা',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('রিকোয়েস্ট পাঠান'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'আগের রিকোয়েস্ট',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (_requests.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('কোনো রিকোয়েস্ট নেই')),
                  )
                else
                  ..._requests.map((r) {
                    return Card(
                      child: ListTile(
                        title: Text('${r['coins']} কয়েন'),
                        subtitle: Text(_statusBn(r['status']?.toString())),
                        trailing: Text(
                          (r['created_at']?.toString() ?? '').split('T').first,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
