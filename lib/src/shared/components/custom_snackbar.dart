import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum SnackBarType {
  success,
  error,
  warning,
  info,
}

class CustomSnackBar {
  static void show({
    required BuildContext context,
    required String message,
    String? title,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    bool showCloseIcon = true,
    bool dismissible = true,
    String? actionLabel,
    VoidCallback? onAction,
    int maxMessageLines = 3,
    bool compact = false,
  }) {
    final color = _getColorForType(type);
    final icon = _getIconForType(type);

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        showCloseIcon: compact ? false : showCloseIcon,
        dismissDirection: dismissible ? DismissDirection.down : DismissDirection.none,
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
        content: Container(
          padding: EdgeInsets.symmetric(
            vertical: compact ? 2 : 4,
            horizontal: compact ? 0 : 0,
          ),
          child: Row(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            children: [
              if (!compact) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              ] else ...[
                Icon(
                  icon,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null && title.trim().isNotEmpty && !compact) ...[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 12 : 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      message,
                      maxLines: compact ? 1 : maxMessageLines,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 13 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: compact ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8) : const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 8 : 12),
        ),
        duration: compact ? const Duration(seconds: 2) : duration,
        elevation: compact ? 2 : 4,
      ),
    );
  }

  static Color _getColorForType(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return AppColors.success;
      case SnackBarType.error:
        return AppColors.error;
      case SnackBarType.warning:
        return AppColors.warning;
      case SnackBarType.info:
        return AppColors.primary;
    }
  }

  static IconData _getIconForType(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return Icons.check_circle_outline;
      case SnackBarType.error:
        return Icons.error_outline;
      case SnackBarType.warning:
        return Icons.warning_amber_rounded;
      case SnackBarType.info:
        return Icons.info_outline;
    }
  }

  // Helper methods for easy access
  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    bool showCloseIcon = true,
    bool dismissible = true,
    String? actionLabel,
    VoidCallback? onAction,
    int maxMessageLines = 3,
    bool compact = false,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      type: SnackBarType.success,
      duration: duration,
      showCloseIcon: showCloseIcon,
      dismissible: dismissible,
      actionLabel: actionLabel,
      onAction: onAction,
      maxMessageLines: maxMessageLines,
      compact: compact,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    bool showCloseIcon = true,
    bool dismissible = true,
    String? actionLabel,
    VoidCallback? onAction,
    int maxMessageLines = 3,
    bool compact = false,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      type: SnackBarType.error,
      duration: duration,
      showCloseIcon: showCloseIcon,
      dismissible: dismissible,
      actionLabel: actionLabel,
      onAction: onAction,
      maxMessageLines: maxMessageLines,
      compact: compact,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    bool showCloseIcon = true,
    bool dismissible = true,
    String? actionLabel,
    VoidCallback? onAction,
    int maxMessageLines = 3,
    bool compact = false,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      type: SnackBarType.warning,
      duration: duration,
      showCloseIcon: showCloseIcon,
      dismissible: dismissible,
      actionLabel: actionLabel,
      onAction: onAction,
      maxMessageLines: maxMessageLines,
      compact: compact,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    bool showCloseIcon = true,
    bool dismissible = true,
    String? actionLabel,
    VoidCallback? onAction,
    int maxMessageLines = 3,
    bool compact = false,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      type: SnackBarType.info,
      duration: duration,
      showCloseIcon: showCloseIcon,
      dismissible: dismissible,
      actionLabel: actionLabel,
      onAction: onAction,
      maxMessageLines: maxMessageLines,
      compact: compact,
    );
  }
}

