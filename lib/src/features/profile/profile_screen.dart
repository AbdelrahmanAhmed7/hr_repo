import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mediconsult_internal/src/core/services/service_locator.dart';
import 'package:mediconsult_internal/src/core/theme/app_colors.dart';
import 'package:mediconsult_internal/src/core/theme/app_text_styles.dart';
import 'package:mediconsult_internal/src/features/profile/cubit/profile_cubit.dart';
import 'package:mediconsult_internal/src/shared/widgets/error_state_widget.dart';

import '../home/models/employee_info.dart';
import 'widgets/profile_settings_section.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ProfileCubit>()..fetchProfile(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1734),
        body: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const _ProfileSimpleLoading();
            } else if (state is ProfileError) {
              return ErrorStateWidget(
                error: state.message,
                onRetry: () => context.read<ProfileCubit>().fetchProfile(),
              );
            } else if (state is ProfileLoaded) {
              final employeeInfo = state.profile.toEmployeeInfo();
              return _ProfileBody(employeeInfo: employeeInfo);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ProfileSimpleLoading extends StatelessWidget {
  const _ProfileSimpleLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F6FB),
      body: SafeArea(
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Main body
// ─────────────────────────────────────────────
class _ProfileBody extends StatelessWidget {
  final EmployeeInfo employeeInfo;

  const _ProfileBody({required this.employeeInfo});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Hero ──
        SliverToBoxAdapter(child: _ProfileHero(employeeInfo: employeeInfo)),

        // ── White sheet starts here ──
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF4F6FB),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _PrimaryActions(),
                ),

                const SizedBox(height: 20),

                // Snapshot
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ProfileSnapshot(employeeInfo: employeeInfo),
                ),

                const SizedBox(height: 16),

                // Settings
                const ProfileSettingsSection(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Hero — avatar + name + position
// ─────────────────────────────────────────────
class _ProfileHero extends StatelessWidget {
  final EmployeeInfo employeeInfo;

  const _ProfileHero({required this.employeeInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B1734),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page title
              Text(
                'الملف الشخصي',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.50),
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 24),

              // Avatar + name row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: _ProfileAvatar(
                        name: employeeInfo.name,
                        imageUrl: employeeInfo.profileImageUrl,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fallback(employeeInfo.name),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Position pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Text(
                            _fallback(employeeInfo.position),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.90),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _fallback(employeeInfo.department),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;

  const _ProfileAvatar({required this.name, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final hasUrl = url != null && url.isNotEmpty;

    if (!hasUrl) return _InitialsAvatar(name: name);

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, imageUrl) => _InitialsAvatar(name: name),
      errorWidget: (context, imageUrl, error) => _InitialsAvatar(name: name),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String name;

  const _InitialsAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: AppTextStyles.headlineSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Primary actions
// ─────────────────────────────────────────────
class _PrimaryActions extends StatelessWidget {
  const _PrimaryActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            title: 'الملف الكامل',
            icon: Icons.person_search_rounded,
            accent: const Color(0xFF246BFD),
            onTap: () => context.push('/profile/full'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            title: 'تعديل البيانات',
            icon: Icons.edit_note_rounded,
            accent: const Color(0xFF0F9D58),
            onTap: () => context.push('/profile/edit'),
            isEnabled: false,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;
  final bool isEnabled;

  const _ActionButton({
    required this.title,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = isEnabled ? accent : Colors.grey.shade400;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: effectiveAccent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: effectiveAccent, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isEnabled
                          ? AppColors.textPrimary
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: isEnabled
                      ? AppColors.textSecondary
                      : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Snapshot — redesigned as a clean list
// ─────────────────────────────────────────────
class _ProfileSnapshot extends StatelessWidget {
  final EmployeeInfo employeeInfo;

  const _ProfileSnapshot({required this.employeeInfo});

  @override
  Widget build(BuildContext context) {
    final items = [
      _SnapItem(
        label: 'كود الموظف',
        value: _fallback(employeeInfo.employeeCode),
        icon: Icons.badge_outlined,
        accent: const Color(0xFFF2994A),
      ),
      _SnapItem(
        label: 'المدير المباشر',
        value: _fallback(employeeInfo.managerName),
        icon: Icons.supervisor_account_outlined,
        accent: const Color(0xFF9B51E0),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1734).withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    size: 17,
                    color: Color(0xFF0B1734),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نظرة سريعة',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: AppColors.border),

          // Items list
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Column(
              children: [
                _SnapRow(item: item),
                if (i < items.length - 1)
                  Divider(
                    height: 1,
                    indent: 60,
                    color: AppColors.border.withValues(alpha: 0.6),
                  ),
              ],
            );
          }),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _SnapItem {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _SnapItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });
}

class _SnapRow extends StatelessWidget {
  final _SnapItem item;

  const _SnapRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          // Icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.accent, size: 18),
          ),

          const SizedBox(width: 14),

          // Label + value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.copyWith(
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
}

// ─────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────
String _fallback(String? value) {
  if (value == null || value.trim().isEmpty || value.trim() == 'null') {
    return 'غير محدد';
  }
  return value.trim();
}

String _initials(String? name) {
  if (name == null || name.trim().isEmpty) return '؟';
  final parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}';
  }
  return parts[0][0];
}
