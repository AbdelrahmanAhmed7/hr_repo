import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Mixin to automatically dismiss keyboard when it's closed
/// Prevents keyboard from reopening after navigation
mixin KeyboardDismissMixin<T extends StatefulWidget> on State<T>
    implements WidgetsBindingObserver {
  double _previousKeyboardHeight = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize with current keyboard height
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _previousKeyboardHeight = View.of(context).viewInsets.bottom;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    
    final viewInsets = View.of(context).viewInsets;
    final currentKeyboardHeight = viewInsets.bottom;
    
    // Only unfocus if keyboard transitioned from open to closed
    // This prevents dismissing focus when keyboard is opening
    if (_previousKeyboardHeight > 0 && currentKeyboardHeight == 0) {
      // Use a small delay to ensure keyboard is fully closed
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        
        // Double check that keyboard is still closed before unfocusing
        final currentViewInsets = View.of(context).viewInsets;
        if (currentViewInsets.bottom == 0) {
          FocusScope.of(context).unfocus();
        }
      });
    }
    
    _previousKeyboardHeight = currentKeyboardHeight;
  }

  // Empty implementations for other WidgetsBindingObserver methods
  @override
  void didChangeAccessibilityFeatures() {}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}

  @override
  void didChangeLocales(List<Locale>? locales) {}

  @override
  void didChangePlatformBrightness() {}

  @override
  void didChangeTextScaleFactor() {}

  @override
  void didHaveMemoryPressure() {}

  @override
  void didChangeViewFocus(ViewFocusEvent event) {}

  @override
  Future<bool> didPopRoute() async => false;

  @override
  Future<bool> didPushRoute(String route) async => false;

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) async => false;

  @override
  Future<AppExitResponse> didRequestAppExit() async => AppExitResponse.exit;

  @override
  void handleCancelBackGesture() {}

  @override
  void handleCommitBackGesture() {}

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) => false;

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {}

  @override
  void handleStatusBarTap() {}
}

