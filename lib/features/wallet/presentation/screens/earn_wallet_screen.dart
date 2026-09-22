import 'package:flutter/material.dart';
import '../../../../core/constants/coin_constants.dart';
import '../../../../core/services/monetization_service.dart';
import '../../../../core/theme/app_colors.dart';

class EarnWalletScreen extends StatefulWidget {
  const EarnWalletScreen({super.key});

  @override
  State<EarnWalletScreen> createState() => _EarnWalletScreenState();
}

class _EarnWalletScreenState extends State<EarnWalletScreen> {
  final _monetization = MonetizationService();
  bool _loading = true;
  bool _enabled = false;
  int _coins = 0;
  Duration _cooldown = Duration.zero;
  List<Map<String, dynamic>> _tx = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await _monetization.isMonetizationEnabled();
    final coins = await _monetization.getMyCoins();
    final cooldown = await _monetization.adCooldownRemaining();
    final tx = await _monetization.getMyTransactions();
    setState(() {
      _enabled = enabled;
      _coins = coins;
      _cooldown = cooldown;
      _tx = tx;
      _loading = false;
    });
  }

  Future<void> _watchAd() async {
    if (!_enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('মনিটাইজেশন এখন বন্ধ')),
      );
      return;
    }
    if (_cooldown > Duration.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'অপেক্ষা করুন ${_cooldown.inSeconds} সেকেন্ড',
          ),
        ),
      );
      return;
    }
    try {
      await _monetization.claimAdReward();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'বিজ্ঞাপন সিস্টেম এখনো যুক্ত হয়নি। পরে AppLovin সংযোগ করুন।',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('ওয়ালেট / কয়েন আয়')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            '$_coins',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text('আপনার কয়েন'),
                          const SizedBox(height: 8),
                          Text(
                            _enabled
                                ? 'মনিটাইজেশন চালু'
                                : 'মনিটাইজেশন বন্ধ — সব কনটেন্ট ফ্রি',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_enabled) ...[
                    ElevatedButton.icon(
                      onPressed: _watchAd,
                      icon: const Icon(Icons.play_circle_outline),
                      label: Text(
                        _cooldown > Duration.zero
                            ? 'অপেক্ষা ${_cooldown.inSeconds}s'
                            : 'বিজ্ঞাপন দেখে ${CoinConstants.adReward} কয়েন নিন',
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'প্রতি ${CoinConstants.adCooldownSeconds} সেকেন্ডে সর্বোচ্চ ১টি বিজ্ঞাপন',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ] else
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('মনিটাইজেশন বন্ধ'),
                        subtitle: Text(
                          'অ্যাডমিন চালু করলে এখানে বিজ্ঞাপন দেখে কয়েন আয় করা যাবে।',
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'সাম্প্রতিক লেনদেন',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (_tx.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('কোনো লেনদেন নেই')),
                    )
                  else
                    ..._tx.map((t) {
                      final amount = (t['amount'] as num?)?.toInt() ?? 0;
                      final type = t['type']?.toString() ?? '';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(type),
                        trailing: Text(
                          amount >= 0 ? '+$amount' : '$amount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: amount >= 0 ? Colors.green : Colors.redAccent,
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
