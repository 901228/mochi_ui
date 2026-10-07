import "package:flutter/scheduler.dart";
import "package:flutter/widgets.dart";

import "../theme/geometry.dart";
import "../theme/theme.dart";
import "../theme/typography.dart";
import "shape_shadow.dart";

/// Shows [message] on hover (mouse), long press (touch), or keyboard focus.
///
/// On touch, a descendant with its own long-press handler (e.g. a button with `onLongPress`)
/// wins the gesture, so the tooltip won't show there.
class MochiTooltip extends StatefulWidget {
  const MochiTooltip({
    super.key,
    required this.message,
    required this.child,
    this.content,
    this.preferBelow = false,
    this.gap = 6,
    this.hoverDelay = const Duration(milliseconds: 500),
  });

  /// Shown in the tooltip and announced by screen readers.
  final String message;

  /// Replaces the default text content; [message] is still used for semantics.
  final Widget? content;
  final Widget child;
  final bool preferBelow;

  /// Distance between the child and the tooltip.
  final double gap;
  final Duration hoverDelay;

  @override
  State<MochiTooltip> createState() => _MochiTooltipState();
}

class _MochiTooltipState extends State<MochiTooltip> {
  final _tooltipKey = GlobalKey<RawTooltipState>();

  // Passed as a tear-off: tear-offs of the same method on the same object are ==,
  // so RawTooltip doesn't relayout on every rebuild.
  Offset _position(TooltipPositionContext c) => positionDependentBox(
    size: c.overlaySize,
    childSize: c.tooltipSize,
    target: c.target,
    preferBelow: widget.preferBelow,
    verticalOffset: c.targetSize.height / 2 + widget.gap,
  );

  // RawTooltip has no focus handling and no per-instance hide, so focus is bridged here.
  void _handleFocusChange(bool focused) {
    if (!focused) {
      RawTooltip.dismissAllToolTips();
      return;
    }
    if (FocusManager.instance.highlightMode != FocusHighlightMode.traditional) return;
    // Post-frame: the previously focused tooltip's blur (which dismisses all tooltips)
    // may be delivered after this focus event.
    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        if (mounted && Focus.maybeOf(context)?.hasFocus != false) {
          _tooltipKey.currentState?.ensureTooltipVisible();
        }
      })
      ..ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: _handleFocusChange,
      child: RawTooltip(
        key: _tooltipKey,
        semanticsTooltip: widget.message,
        hoverDelay: widget.hoverDelay,
        positionDelegate: _position,
        ignorePointer: true,
        tooltipBuilder: (context, animation) =>
            _TooltipBubble(animation: animation, child: widget.content ?? Text(widget.message)),
        child: widget.child,
      ),
    );
  }
}

class _TooltipBubble extends StatelessWidget {
  const _TooltipBubble({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final tone = theme.colors.neutral;

    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween(begin: 0.96, end: 1.0).animate(animation),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: ShapeShadow(
            radius: theme.geometry.radius.xs,
            shadows: theme.geometry.shadows.of(MochiElevation.md, theme.colors.shadow),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: tone.base,
                shape: theme.geometry.shape(borderRadius: theme.geometry.radius.xs),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: DefaultTextStyle(
                  style: theme.typography.body.xs.withWeight(FontWeight.w500).copyWith(color: tone.onBase),
                  child: IconTheme.merge(
                    data: IconThemeData(color: tone.onBase, size: 14),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
