import 'package:fluttertoast/fluttertoast.dart';

enum ToastType { success, error, warning, info }

class CustomToast {
  static DateTime? _lastShownAt;
  static String? _lastMessage;

  static void show({
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    ToastGravity gravity = ToastGravity.BOTTOM,
  }) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    // Prevent toast stacking: always keep only the latest toast visible.
    Fluttertoast.cancel();

    // Small dedupe: avoid re-showing same message repeatedly in a tight loop.
    final now = DateTime.now();
    if (_lastMessage == trimmed &&
        _lastShownAt != null &&
        now.difference(_lastShownAt!) < const Duration(milliseconds: 800)) {
      return;
    }
    _lastMessage = trimmed;
    _lastShownAt = now;

    Fluttertoast.showToast(
      msg: trimmed,
      toastLength: duration.inSeconds <= 2
          ? Toast.LENGTH_SHORT
          : Toast.LENGTH_LONG,
      gravity: gravity,
      fontSize: 16,
    );
  }

  static void showSuccess(String message, {Duration? duration}) {
    show(
      message: message,
      type: ToastType.success,
      duration: duration ?? const Duration(seconds: 2),
    );
  }

  static void showError(String message, {Duration? duration}) {
    show(
      message: message,
      type: ToastType.error,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  static void showWarning(String message, {Duration? duration}) {
    show(
      message: message,
      type: ToastType.warning,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  static void showInfo(String message, {Duration? duration}) {
    show(
      message: message,
      type: ToastType.info,
      duration: duration ?? const Duration(seconds: 2),
    );
  }
}
