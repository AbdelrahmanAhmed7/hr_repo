import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class FloatingLegend extends StatefulWidget {
  const FloatingLegend({super.key});

  @override
  State<FloatingLegend> createState() => _FloatingLegendState();
}

class _FloatingLegendState extends State<FloatingLegend>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _scaleController.forward();
      } else {
        _scaleController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(_isExpanded ? 12 : 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(_isExpanded ? 20 : 24),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isExpanded ? 0.12 : 0.08),
            blurRadius: _isExpanded ? 16 : 10,
            offset: Offset(0, _isExpanded ? 6 : 4),
            spreadRadius: _isExpanded ? 1 : 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isExpanded ? Icons.close : Icons.info_outline,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: _isExpanded
                ? Row(
                    children: [
                      const SizedBox(width: 12),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: _buildLegendItem(AppColors.primary, 'CEO'),
                      ),
                      const SizedBox(width: 12),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: _buildLegendItem(AppColors.warning, 'مدير'),
                      ),
                      const SizedBox(width: 12),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: _buildLegendItem(AppColors.primaryLight, 'موظف'),
                      ),
                      const SizedBox(width: 4),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
