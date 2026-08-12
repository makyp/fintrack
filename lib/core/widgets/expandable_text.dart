import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One-line text that can be unfolded with an eye button when it does not fit.
///
/// Descriptions coming from a receipt photo list several products, so a single
/// ellipsised line is unreadable. The eye only appears when the text actually
/// overflows — rows that fit stay clean.
class ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  /// Lines shown while collapsed.
  final int collapsedMaxLines;

  const ExpandableText({
    super.key,
    required this.text,
    this.style,
    this.collapsedMaxLines = 1,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  void didUpdateWidget(ExpandableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A recycled row showing different content starts collapsed again.
    if (oldWidget.text != widget.text) _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DefaultTextStyle.of(context).style;

    return LayoutBuilder(
      builder: (context, constraints) {
        final overflows = _overflows(context, style, constraints.maxWidth);

        final text = Text(
          widget.text,
          style: style,
          maxLines: _expanded ? null : widget.collapsedMaxLines,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        );

        if (!overflows) return text;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: text),
            // Its own tap target, so unfolding never opens the row behind it.
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.only(left: 6, top: 1, bottom: 1),
                child: Icon(
                  _expanded
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 16,
                  color: AppColors.grey500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Measures at the full available width: if the text fits there we render it
  /// without the eye, so the two decisions stay consistent.
  bool _overflows(BuildContext context, TextStyle style, double maxWidth) {
    if (maxWidth.isInfinite) return false;
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: style),
      maxLines: widget.collapsedMaxLines,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }
}
