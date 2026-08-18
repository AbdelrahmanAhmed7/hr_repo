import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/nominee_model.dart';

class NomineeCard extends StatelessWidget {
  final NomineeModel nominee;
  final bool hasVoted;
  final bool isVotedFor;
  final bool isVoteLoading;
  final VoidCallback? onTap;

  const NomineeCard({
    super.key,
    required this.nominee,
    required this.hasVoted,
    required this.isVotedFor,
    required this.isVoteLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = hasVoted || isVoteLoading;

    return Opacity(
      opacity: (hasVoted && !isVotedFor) ? 0.6 : 1.0,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isVotedFor ? AppColors.success : AppColors.border,
              width: isVotedFor ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isVotedFor
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.border.withValues(alpha: 0.3),
                blurRadius: isVotedFor ? 12 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              _Avatar(
                imageUrl: nominee.imageUrl,
                name: nominee.fullNameAr,
                isVotedFor: isVotedFor,
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nominee.fullNameAr,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      nominee.jobTitleName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Trailing indicator
              if (isVoteLoading && !hasVoted)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                )
              else if (isVotedFor)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                )
              else if (!disabled)
                const Icon(
                  Icons.how_to_vote_outlined,
                  color: AppColors.textTertiary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final bool isVotedFor;

  const _Avatar({
    required this.imageUrl,
    required this.name,
    required this.isVotedFor,
  });

  String get _initial {
    final trimmed = name.trim();
    return trimmed.isNotEmpty ? trimmed[0] : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryTint,
        border: isVotedFor
            ? Border.all(color: AppColors.success, width: 2)
            : null,
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _Initials(initial: _initial),
              ),
            )
          : _Initials(initial: _initial),
    );
  }
}

class _Initials extends StatelessWidget {
  final String initial;
  const _Initials({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: AppTextStyles.titleMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
