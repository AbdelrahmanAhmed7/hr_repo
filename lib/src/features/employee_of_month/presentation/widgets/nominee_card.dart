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

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: (hasVoted && !isVotedFor) ? 0.55 : 1.0,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isVotedFor ? const Color(0xFFF59E0B) : AppColors.border,
              width: isVotedFor ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(
                  alpha: isVotedFor ? 0.18 : 0.06,
                ),
                blurRadius: isVotedFor ? 16 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              _Avatar(
                imageUrl: nominee.imageUrl,
                name: nominee.fullNameAr,
                isVotedFor: isVotedFor,
              ),
              const SizedBox(width: 14),
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
              _buildTrailing(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrailing() {
    if (isVoteLoading && !hasVoted) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
        ),
      );
    }
    if (isVotedFor) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
            SizedBox(width: 5),
            Text(
              'تم التصويت',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
    if (hasVoted) {
      return const Icon(
        Icons.how_to_vote_outlined,
        color: AppColors.textTertiary,
        size: 22,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.how_to_vote_rounded, color: Color(0xFFB45309), size: 16),
          SizedBox(width: 5),
          Text(
            'صوّت',
            style: TextStyle(
              color: Color(0xFF92400E),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isVotedFor
              ? const [Color(0xFFFBBF24), Color(0xFFD97706)]
              : const [Color(0xFFDBEAFE), Color(0xFF93C5FD)],
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: ClipOval(
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _Initials(initial: _initial),
                )
              : _Initials(initial: _initial),
        ),
      ),
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