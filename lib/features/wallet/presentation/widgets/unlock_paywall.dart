import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class UnlockPaywall extends StatelessWidget {
  final String title;
  final int cost;
  final int userCoins;
  final VoidCallback onUnlockPressed;

  const UnlockPaywall({
    super.key,
    required this.title,
    required this.cost,
    required this.userCoins,
    required this.onUnlockPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canAfford = userCoins >= cost;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'আনলক করতে $cost কয়েন লাগবে',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'আপনার ব্যালেন্স: $userCoins কয়েন',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canAfford ? onUnlockPressed : null,
                    child: Text(
                      canAfford ? '$cost কয়েন দিয়ে খুলুন' : 'কয়েন কম আছে',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.push('/wallet'),
                  child: const Text('ওয়ালেটে গিয়ে কয়েন আয় করুন'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
