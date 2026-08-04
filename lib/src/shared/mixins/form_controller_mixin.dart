import 'package:flutter/material.dart';

/// Mixin to help manage TextEditingControllers in form screens
/// Automatically disposes all controllers when the widget is disposed
mixin FormControllerMixin<T extends StatefulWidget> on State<T> {
  final List<TextEditingController> _controllers = [];

  /// Register a controller to be automatically disposed
  void registerController(TextEditingController controller) {
    _controllers.add(controller);
  }

  /// Register multiple controllers at once
  void registerControllers(List<TextEditingController> controllers) {
    _controllers.addAll(controllers);
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }
}

