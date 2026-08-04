import 'package:flutter/material.dart';
import '../models/employee_info.dart';

/// A clean, flat header with no gradients or decorative blobs.
/// Primary color is deep navy-blue [_kHeaderBg] — swap it or pull it
/// from AppColors whenever the palette is finalised.
class HeaderSection extends StatelessWidget {
  final EmployeeInfo employeeInfo;
  final String greeting;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMenuTap;

  // ── Deep navy – change this one constant to repaint the whole header ──
  static const Color _kHeaderBg = Color(0xFF0D2B6E);
  static const Color _kSurface   = Colors.white;

  const HeaderSection({
    super.key,
    required this.employeeInfo,
    this.greeting = '',
    this.onNotificationTap,
    this.onMenuTap,
  });

  // ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kHeaderBg,
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopRow(
                employeeInfo:      employeeInfo,
                greeting:          greeting.isNotEmpty ? greeting : _timeGreeting(),
                onNotificationTap: onNotificationTap,
              ),
              const SizedBox(height: 22),
              _ChipsRow(employeeInfo: employeeInfo),
            ],
          ),
        ),
      ),
    );
  }

  static String _timeGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'صباح الخير 👋';
    if (h < 17) return 'مساء الخير 👋';
    return 'مساء النور 👋';
  }
}

// ── Top row: greeting + name + notification button ────────────────────
class _TopRow extends StatelessWidget {
  final EmployeeInfo employeeInfo;
  final String greeting;
  final VoidCallback? onNotificationTap;

  const _TopRow({
    required this.employeeInfo,
    required this.greeting,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Text ──
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(
                  color:      Color(0x99FFFFFF), // white 60 %
                  fontSize:   13,
                  fontWeight: FontWeight.w500,
                  height:     1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                employeeInfo.name,
                maxLines:  1,
                overflow:  TextOverflow.ellipsis,
                style: const TextStyle(
                  color:         HeaderSection._kSurface,
                  fontSize:      24,
                  fontWeight:    FontWeight.w800,
                  letterSpacing: -0.5,
                  height:        1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // ── Notification button ──
        _NotifButton(
          count:  employeeInfo.notificationCount,
          onTap:  onNotificationTap,
        ),
      ],
    );
  }
}

// ── Notification icon button with badge ──────────────────────────────
class _NotifButton extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const _NotifButton({required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color:        Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap:        onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width:  44,
              height: 44,
              decoration: BoxDecoration(
                color:        const Color(0x1AFFFFFF), // white 10 %
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0x26FFFFFF),      // white 15 %
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: HeaderSection._kSurface,
                size:  22,
              ),
            ),
          ),
        ),
        if (count > 0)
          Positioned(
            top:   -4,
            right: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color:  const Color(0xFFFF4757),
                shape:  BoxShape.circle,
                border: Border.all(
                  color: HeaderSection._kHeaderBg,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color:      HeaderSection._kSurface,
                    fontSize:   9,
                    fontWeight: FontWeight.w700,
                    height:     1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Chips row: department + position ─────────────────────────────────
class _ChipsRow extends StatelessWidget {
  final EmployeeInfo employeeInfo;

  const _ChipsRow({required this.employeeInfo});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection:  Axis.horizontal,
      physics:          const BouncingScrollPhysics(),
      child: Row(
        children: [
          _Chip(
            icon: Icons.business_center_rounded,
            label: employeeInfo.department,
          ),
          const SizedBox(width: 8),
          _Chip(
            icon: Icons.person_outline_rounded,
            label: employeeInfo.position,
            dimmed: true,
          ),
        ],
      ),
    );
  }
}

// ── Single chip ───────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     dimmed;

  const _Chip({
    required this.icon,
    required this.label,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = dimmed
        ? const Color(0xB3FFFFFF)   // white 70 %
        : HeaderSection._kSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color:        const Color(0x1AFFFFFF),  // white 10 %
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0x26FFFFFF),        // white 15 %
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color:      color,
              fontSize:   12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}