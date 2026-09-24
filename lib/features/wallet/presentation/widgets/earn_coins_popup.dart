import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

/// কয়েন শর্ট হলে সব জায়গায় এই পপআপ।
class EarnCoinsPopup {
  static Future<void> show(
    BuildContext context, {
    String? message,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('কয়েন কম আছে'),
        content: Text(
          message ??
              'এই কাজের জন্য যথেষ্ট কয়েন নেই। বিজ্ঞাপন দেখে কয়েন জমা করুন — যতবার ইচ্ছা দেখতে পারবেন।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বন্ধ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/wallet');
            },
            child: const Text('বিজ্ঞাপন দেখে কয়েন জমা করুন'),
          ),
        ],
      ),
    );
  }

  /// RPC/Exception থেকে "Insufficient" ধরলে true
  static bool isInsufficientError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('insufficient') ||
        s.contains('কয়েন') && s.contains('কম') ||
        s.contains('not enough');
  }
}
