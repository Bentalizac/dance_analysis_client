import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// On web, centers [child] horizontally and constrains its width to
/// [maxWidth]. On all other platforms the child is returned unchanged.
///
/// Uses [Align] (not [Center]) so that the child fills the available height
/// correctly — important for full-height scrollables like [ListView].
class WebConstrainedBody extends StatelessWidget {
  const WebConstrainedBody({
    super.key,
    required this.child,
    this.maxWidth = 960,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
