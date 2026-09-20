import 'package:flutter/material.dart';

import '../../data/models/winner_model.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/cached_image_widget.dart';
import '../../../../core/theme/app_colors.dart';

class WinnerCard extends StatelessWidget {
  final WinnerModel winner;
  final int? rank;

  const WinnerCard({super.key, required this.winner, this.rank});

  String get _initial {
    final trimmed = winner.fullNameAr.trim();
    return trimmed.isNotEmpty ? trimmed[0] : '?';
  }

  @override
  Widget build(BuildContext context) {
    final medal = _medalFor(rank);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (medal != null) ...[
            _MedalBadge(medal: medal),
            const SizedBox(width: 12),
          ],
          _Avatar(initial: _initial, imageUrl: winner.imageUrl),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  winner.fullNameAr,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF92400E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  winner.departmentName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFFB45309),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.how_to_vote_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${winner.voteCount}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _medalFor(int? rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return rank == null ? null : '$rank';
    }
  }
}

class _MedalBadge extends StatelessWidget {
  final String medal;
  const _MedalBadge({required this.medal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
      ),
      child: Text(
        medal,
        style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initial;
  final String? imageUrl;

  const _Avatar({required this.initial, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return CachedAvatarWidget(
      imageUrl: imageUrl,
      initials: initial,
      size: 52,
      backgroundColor: AppColors.primaryTint,
      textColor: AppColors.primary,
    );
  }
}