import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mediconsult_internal/src/core/services/service_locator.dart';
import 'package:mediconsult_internal/src/core/theme/app_colors.dart';
import 'package:mediconsult_internal/src/core/theme/app_text_styles.dart';
import 'package:mediconsult_internal/src/features/profile/cubit/profile_cubit.dart';
import 'package:mediconsult_internal/src/shared/widgets/error_state_widget.dart';

import 'models/profile_response.dart';

class FullProfileScreen extends StatelessWidget {
  const FullProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ProfileCubit>()..fetchProfile(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1734),
        body: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const _FullProfileSkeleton();
            } else if (state is ProfileError) {
              return ErrorStateWidget(
                error: state.message,
                onRetry: () => context.read<ProfileCubit>().fetchProfile(),
              );
            } else if (state is ProfileLoaded) {
              return _FullProfileContent(profile: state.profile);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Main content
// ─────────────────────────────────────────────
class _FullProfileContent extends StatelessWidget {
  final ProfileResponse profile;

  const _FullProfileContent({required this.profile});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Collapsible hero ──
        SliverAppBar(
          pinned: true,
          elevation: 0,
          backgroundColor: const Color(0xFF0B1734),
          expandedHeight: 220,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            onPressed: () => context.pop(),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: IconButton(
                icon: Icon(
                  Icons.edit_rounded,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
                onPressed: null,
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _FullProfileHero(profile: profile),
          ),
        ),

        // ── White sheet ──
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF4F6FB),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
              child: Column(
                children: [
                  // Personal info
                  _SectionCard(
                    title: 'المعلومات الشخصية',
                    icon: Icons.person_outline_rounded,
                    accent: const Color(0xFF246BFD),
                    rows: [
                      _Row(
                        'الاسم بالعربي',
                        profile.fullNameAr,
                        Icons.badge_outlined,
                      ),
                      _Row(
                        'الاسم بالإنجليزي',
                        profile.fullNameEn,
                        Icons.translate_rounded,
                      ),
                      _Row(
                        'تاريخ الميلاد',
                        _formatDate(profile.birthday),
                        Icons.cake_outlined,
                      ),
                      _Row(
                        'النوع',
                        profile.isMale ? 'ذكر' : 'أنثى',
                        profile.isMale
                            ? Icons.male_rounded
                            : Icons.female_rounded,
                      ),
                      _Row(
                        'الجنسية',
                        profile.nationalityName,
                        Icons.public_outlined,
                      ),
                      _Row(
                        'الحالة الاجتماعية',
                        profile.maritalStatusName,
                        Icons.favorite_outline_rounded,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Job info
                  _SectionCard(
                    title: 'المعلومات الوظيفية',
                    icon: Icons.work_outline_rounded,
                    accent: const Color(0xFF0F9D58),
                    rows: [
                      _Row(
                        'كود الموظف',
                        profile.employeeCode,
                        Icons.badge_outlined,
                      ),
                      _Row(
                        'المسمى الوظيفي',
                        profile.jobTitleName ?? profile.jobTitle,
                        Icons.work_outline_rounded,
                      ),
                      _Row(
                        'القسم',
                        profile.departmentName,
                        Icons.business_outlined,
                      ),
                      _Row(
                        'الفرع',
                        profile.branchName,
                        Icons.apartment_outlined,
                      ),
                      _Row(
                        'المدير المباشر',
                        profile.managerName,
                        Icons.supervisor_account_outlined,
                      ),
                      _Row(
                        'تاريخ التعيين',
                        _formatDate(profile.startDate),
                        Icons.calendar_today_outlined,
                      ),
                      _Row(
                        'نمط العمل',
                        profile.employmentModeName,
                        Icons.access_time_rounded,
                      ),
                      _Row(
                        'كود الماكينة',
                        profile.machineCode,
                        Icons.computer_outlined,
                      ),
                      _Row(
                        'كود البصمة',
                        profile.fingerprintKey,
                        Icons.fingerprint_rounded,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Contact
                  _SectionCard(
                    title: 'بيانات التواصل',
                    icon: Icons.phone_outlined,
                    accent: const Color(0xFFF2994A),
                    rows: [
                      _Row(
                        'الموبايل',
                        profile.phoneNumber,
                        Icons.phone_iphone_rounded,
                        highlight: true,
                      ),
                      _Row(
                        'البريد الشخصي',
                        profile.email,
                        Icons.email_outlined,
                        highlight: true,
                      ),
                      _Row(
                        'بريد الشركة',
                        profile.companyEmail,
                        Icons.corporate_fare_outlined,
                      ),
                      _Row(
                        'هاتف الشركة',
                        profile.companyPhoneNumber,
                        Icons.phone_outlined,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Identity & address
                  _SectionCard(
                    title: 'الهوية والعنوان',
                    icon: Icons.badge_outlined,
                    accent: const Color(0xFF9B51E0),
                    rows: [
                      _Row(
                        'الرقم القومي',
                        profile.nationalId,
                        Icons.credit_card_outlined,
                      ),
                      _Row(
                        'جواز السفر',
                        profile.passportNumber,
                        Icons.airplane_ticket_outlined,
                      ),
                      _Row('العنوان', profile.addressAr, Icons.home_outlined),
                      _Row(
                        'العنوان بالإنجليزي',
                        profile.addressEn,
                        Icons.home_work_outlined,
                      ),
                      _Row(
                        'المحافظة',
                        profile.governorateName,
                        Icons.location_city_outlined,
                      ),
                      _Row(
                        'المدينة',
                        profile.cityName,
                        Icons.location_on_outlined,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Edit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('تعديل الملف الشخصي'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: AppTextStyles.buttonLarge,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Hero
// ─────────────────────────────────────────────
class _ChipData {
  final IconData icon;
  final String label;
  const _ChipData(this.icon, this.label);
}

class _FullProfileHero extends StatelessWidget {
  final ProfileResponse profile;

  const _FullProfileHero({required this.profile});

  @override
  Widget build(BuildContext context) {
    final chips = <_ChipData>[
      if (_hasValue(profile.employeeCode))
        _ChipData(Icons.fingerprint, 'كود ${profile.employeeCode}'),
      if (_hasValue(profile.jobTitleName ?? profile.jobTitle))
        _ChipData(
          Icons.work_outline_rounded,
          profile.jobTitleName ?? profile.jobTitle!,
        ),
      if (_hasValue(profile.departmentName))
        _ChipData(Icons.business_outlined, profile.departmentName!),
      if (_hasValue(profile.branchName))
        _ChipData(Icons.apartment_outlined, profile.branchName!),
      if (profile.startDate != null)
        _ChipData(
          Icons.calendar_today_outlined,
          _formatDate(profile.startDate),
        ),
    ];

    return Container(
      color: const Color(0xFF0B1734),
      padding: const EdgeInsets.fromLTRB(20, 90, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar (image if available)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: _FullProfileAvatar(
                    name: profile.fullNameAr,
                    imageUrl: profile.imageUrl,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fullName(profile),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Active dot
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: profile.isActive
                                ? const Color(0xFF34D399)
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          profile.isActive ? 'موظف نشط' : 'غير نشط',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.60),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          profile.isMale ? '• ذكر' : '• أنثى',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Chips — scrollable horizontally
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: chips
                    .map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _HeroChip(icon: c.icon, label: c.label),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FullProfileAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;

  const _FullProfileAvatar({required this.name, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final hasUrl = url != null && url.isNotEmpty;
    if (!hasUrl) return _FullInitials(name: name);

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, imageUrl) => _FullInitials(name: name),
      errorWidget: (context, imageUrl, error) => _FullInitials(name: name),
    );
  }
}

class _FullInitials extends StatelessWidget {
  final String name;

  const _FullInitials({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: AppTextStyles.titleLarge.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Section card — list style rows with dividers
// ─────────────────────────────────────────────
class _Row {
  final String label;
  final String? value;
  final IconData icon;
  final bool highlight;

  const _Row(this.label, this.value, this.icon, {this.highlight = false});
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final List<_Row> rows;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final visible = rows
        .where(
          (r) =>
              r.value != null &&
              r.value!.trim().isNotEmpty &&
              r.value!.trim() != 'null',
        )
        .toList();

    if (visible.isEmpty) return const SizedBox.shrink();

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
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accent, size: 17),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.border),

          // Rows
          ...visible.asMap().entries.map((entry) {
            final i = entry.key;
            final row = entry.value;
            return Column(
              children: [
                _InfoListRow(row: row, accent: accent),
                if (i < visible.length - 1)
                  Divider(
                    height: 1,
                    indent: 62,
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

class _InfoListRow extends StatelessWidget {
  final _Row row;
  final Color accent;

  const _InfoListRow({required this.row, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(row.icon, color: accent, size: 17),
          ),

          const SizedBox(width: 14),

          // Label + value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  row.value!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: row.highlight
                        ? const Color(0xFF246BFD)
                        : AppColors.textPrimary,
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
//  Skeleton
// ─────────────────────────────────────────────
class _FullProfileSkeleton extends StatelessWidget {
  const _FullProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F6FB),
      body: SafeArea(
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Hero chip widget
// ─────────────────────────────────────────────
class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.70)),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
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
String _formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  try {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd / MM / yyyy').format(date);
  } catch (_) {
    return dateStr;
  }
}

String _fallback(String? value) {
  if (value == null || value.trim().isEmpty || value.trim() == 'null') {
    return 'غير محدد';
  }
  return value.trim();
}

bool _hasValue(String? value) =>
    value != null && value.trim().isNotEmpty && value.trim() != 'null';

// Builds full name from parts — gracefully handles nulls
String _fullName(ProfileResponse p) {
  final parts = [
    p.firstNameAr,
    p.middleNameAr,
    p.lastNameAr,
  ].where(_hasValue).toList();
  if (parts.isNotEmpty) return parts.join(' ');
  return _fallback(p.fullNameAr);
}

String _initials(String? name) {
  if (name == null || name.trim().isEmpty) return '؟';
  final parts = name.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
  return parts[0][0];
}
