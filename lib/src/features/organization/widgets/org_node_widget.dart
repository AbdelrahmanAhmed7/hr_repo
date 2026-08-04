import 'package:flutter/material.dart';
import 'package:mediconsult_internal/src/core/theme/app_colors.dart';
import '../models/organization_models.dart';

class OrgNodeWidget extends StatefulWidget {
  final dynamic details; // For compatibility, contains .item (Employee)
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool hasSubordinates;
  final int? subordinatesCount;
  final String? position;
  final bool isExpanded; // New: track expansion state
  final VoidCallback? onExpandToggle; // New: callback for expand/collapse

  const OrgNodeWidget({
    super.key,
    required this.details,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.hasSubordinates = false,
    this.subordinatesCount,
    this.position,
    this.isExpanded = true,
    this.onExpandToggle,
  });

  @override
  State<OrgNodeWidget> createState() => _OrgNodeWidgetState();
}

class _OrgNodeWidgetState extends State<OrgNodeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    if (widget.isSelected) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(OrgNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employee = widget.details.item;

    final colors = _getColorsForLevel(employee.level);

    final isHighlighted = employee.isHighlighted;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onDoubleTap: widget.hasSubordinates && widget.onExpandToggle != null
          ? widget.onExpandToggle
          : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
            constraints: BoxConstraints(
              minWidth: 105,
              maxWidth: 125,
              minHeight: widget.position != null && widget.position!.isNotEmpty
                  ? 145
                  : 130,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isHighlighted
                    ? AppColors.warning // Highlight color
                    : widget.isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                width: isHighlighted || widget.isSelected ? 3.5 : 2.5,
              ),
              boxShadow: [
                // Main shadow
                BoxShadow(
                  color: isHighlighted
                      ? AppColors.warning.withValues(alpha: 0.7)
                      : colors[0].withValues(alpha: 0.35),
                  blurRadius: isHighlighted ? 35 : 24,
                  offset: const Offset(0, 10),
                  spreadRadius: isHighlighted ? 6 : 3,
                ),
                // Selected state shadow
                if (widget.isSelected)
                  BoxShadow(
                    color: colors[0].withValues(alpha: 0.6),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                    spreadRadius: 4,
                  ),
                // Soft inner shadow for depth
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                  spreadRadius: -3,
                ),
                // Highlight shadow
                if (isHighlighted)
                  BoxShadow(
                    color: AppColors.warning.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.3),
                              Colors.white.withValues(alpha: 0.15),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(-1, -1),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: employee.imageUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  employee.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildInitials(employee),
                                ),
                              )
                            : _buildInitials(employee),
                      ),
                      if (widget.hasSubordinates && widget.onExpandToggle != null)
                        Positioned(
                          right: -6,
                          bottom: -6,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: widget.onExpandToggle,
                              borderRadius: BorderRadius.circular(12),
                              splashColor: colors[0].withValues(alpha: 0.3),
                              highlightColor: colors[0].withValues(alpha: 0.2),
                              child: Container(
                                width: 24,
                                height: 24,
                                padding: const EdgeInsets.all(1.5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: colors[0], width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors[0].withValues(alpha: 0.4),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  widget.isExpanded
                                      ? Icons.keyboard_arrow_down_rounded
                                      : Icons.keyboard_arrow_right_rounded,
                                  size: 14,
                                  color: colors[0],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Username
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        employee.username,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          letterSpacing: 0.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              offset: const Offset(0, 1),
                              blurRadius: 3,
                            ),
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              offset: const Offset(0, 0.5),
                              blurRadius: 1,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  // Position (if available)
                  if (widget.position != null && widget.position!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          widget.position!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            letterSpacing: 0.1,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                offset: const Offset(0, 0.5),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  // Level badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.35),
                          Colors.white.withValues(alpha: 0.25),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      employee.level.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  // Subordinates count (for managers only)
                  if (widget.subordinatesCount != null &&
                      widget.subordinatesCount! > 0) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.4),
                            Colors.white.withValues(alpha: 0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_rounded,
                            size: 11,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.subordinatesCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildInitials(Employee employee) {
    return Center(
      child: Text(
        employee.initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getColorsForLevel(EmployeeLevel level) {
    switch (level) {
      case EmployeeLevel.ceo:
        return [AppColors.primary, AppColors.primaryDark];
      case EmployeeLevel.manager:
        return [AppColors.warning, const Color(0xFFB87306)];
      case EmployeeLevel.employee:
        return [AppColors.primaryLight, AppColors.primary];
    }
  }
}
