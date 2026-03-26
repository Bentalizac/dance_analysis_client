import 'package:flutter/material.dart';

/// Chat-style note bubble with optional highlighted spans (mentions, timestamps).
class CommentBubble extends StatelessWidget {
  const CommentBubble({
    super.key,
    required this.text,
    this.alignment = Alignment.centerLeft,
    this.highlightedSpans = const [],
  });

  final String text;
  final Alignment alignment;
  final List<String> highlightedSpans;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLeft = alignment == Alignment.centerLeft;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isLeft
                ? colorScheme.surfaceContainerHighest
                : colorScheme.primaryContainer,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isLeft ? 4 : 18),
              bottomRight: Radius.circular(isLeft ? 18 : 4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: _RichBubbleText(
              text: text,
              highlightedSpans: highlightedSpans,
              color: isLeft
                  ? colorScheme.onSurface
                  : colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class _RichBubbleText extends StatelessWidget {
  const _RichBubbleText({
    required this.text,
    required this.highlightedSpans,
    required this.color,
  });

  final String text;
  final List<String> highlightedSpans;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (highlightedSpans.isEmpty) {
      return Text(
        text,
        style: textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final spans = <TextSpan>[];
    var remaining = text;

    for (final highlight in highlightedSpans) {
      final index = remaining.indexOf(highlight);
      if (index < 0) continue;

      if (index > 0) {
        spans.add(TextSpan(
          text: remaining.substring(0, index),
          style: textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ));
      }

      spans.add(TextSpan(
        text: highlight,
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.secondary,
          fontWeight: FontWeight.w600,
        ),
      ));

      remaining = remaining.substring(index + highlight.length);
    }

    if (remaining.isNotEmpty) {
      spans.add(TextSpan(
        text: remaining,
        style: textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ));
    }

    return Text.rich(TextSpan(children: spans));
  }
}
