import 'package:flutter/material.dart';

/// A wrapper that delays building children until they become visible
class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late List<bool> _hasBeenVisible;

  @override
  void initState() {
    super.initState();
    _hasBeenVisible = List.filled(widget.children.length, false);
    // Mark the initial index as visible
    _hasBeenVisible[widget.index] = true;
  }

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mark the new index as visible
    if (widget.index != oldWidget.index) {
      setState(() {
        _hasBeenVisible[widget.index] = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: List.generate(
        widget.children.length,
        (index) {
          // Only build the widget if it has been visible at least once
          if (_hasBeenVisible[index]) {
            return widget.children[index];
          }
          // Return empty container for widgets that haven't been visible yet
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
