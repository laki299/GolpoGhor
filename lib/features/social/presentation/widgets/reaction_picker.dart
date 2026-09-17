import 'package:flutter/material.dart';
import '../../../../core/constants/reaction_types.dart';
import '../../../../core/theme/app_colors.dart';

class ReactionPicker extends StatelessWidget {
  final Function(String reactionType) onReactionSelected;
  final String? currentReaction;

  const ReactionPicker({
    super.key,
    required this.onReactionSelected,
    this.currentReaction,
  });

  static void show(
    BuildContext context, {
    required Function(String) onSelected,
    String? current,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ReactionPicker(
        onReactionSelected: (type) {
          Navigator.pop(context);
          onSelected(type);
        },
        currentReaction: current,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'আপনার প্রতিক্রিয়া দিন',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ReactionTypes.all.map((type) {
              final isSelected = currentReaction == type;
              return GestureDetector(
                onTap: () => onReactionSelected(type),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.15)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        ReactionTypes.getEmoji(type),
                        style: TextStyle(
                          fontSize: isSelected ? 32 : 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ReactionTypes.getLabel(type),
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
