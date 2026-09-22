import "package:flutter/widgets.dart";

import "../theme/size.dart";
import "../theme/styles/button_style.dart";
import "../theme/typography.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "button.dart";

/// The row of page numbers under a long list: ‹ 1 … 4 5 6 … 20 ›.
///
/// Pages are counted from 1. The current one is a solid button and the rest are ghosts, with the
/// arrows at either end stopping at the first and last page. Only [around] pages either side of
/// the current one are written out; the gaps become …, so the row keeps its width whatever page
/// it is on.
///
/// ```dart
/// MochiPagination(
///   page: page,
///   pages: (solves.length / 50).ceil(),
///   onChanged: (next) => setState(() => page = next),
/// )
/// ```
class MochiPagination extends StatelessWidget {
  const MochiPagination({
    super.key,
    required this.page,
    required this.pages,
    required this.onChanged,
    this.around = 1,
    this.size = MochiSize.sm,
    this.intent = MochiIntent.primary,
    this.showArrows = true,
    this.label,
  }) : assert(pages > 0),
       assert(page >= 1),
       assert(around >= 0);

  /// The page being shown, counted from 1.
  final int page;

  /// How many there are.
  final int pages;

  /// Null disables the row.
  final ValueChanged<int>? onChanged;

  /// How many pages to write out either side of the current one.
  final int around;

  final MochiSize size;

  /// Colours the current page's button.
  final MochiIntent intent;

  final bool showArrows;

  /// Names the row for screen readers. Defaults to "Pagination".
  final String? label;

  bool get _enabled => onChanged != null;

  /// How many slots the row has, whatever page it is on: the two ends, two gaps, and a window
  /// of [around] pages either side of the current one.
  int get _slotCount => 2 * around + 5;

  /// The pages to write out, with nulls where a gap was folded away.
  ///
  /// The count is the same on every page — the window slides along and grows at the ends to take
  /// the room a gap gives back — so the row keeps its width instead of jumping about as you page
  /// through it.
  List<int?> get _slots {
    if (pages <= _slotCount) return [for (var p = 1; p <= pages; p++) p];

    final window = 2 * around + 1;
    // Near the start: no gap on the left, so the run there is longer by what the gap cost.
    if (page <= around + 3) {
      return [for (var p = 1; p <= window + 2; p++) p, null, pages];
    }
    if (page >= pages - around - 2) {
      return [1, null, for (var p = pages - window - 1; p <= pages; p++) p];
    }

    return [1, null, for (var p = page - around; p <= page + around; p++) p, null, pages];
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;
    final m = MochiButtonMetrics.of(size, touch: theme.touch, density: theme.density);
    // Every slot is the same width — the widest page number, or a square, whichever is bigger —
    // so the row keeps its width as the window slides and the numbers gain a digit.
    final painter = TextPainter(
      text: TextSpan(text: "$pages", style: m.textStyle(theme.typography).withWeight(FontWeight.w600)),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final side = [m.height, painter.width + m.horizontalPadding].reduce((a, b) => a > b ? a : b);
    painter.dispose();

    // The same metrics as the buttons would have picked, with the padding taken out: the width
    // is the slot's now.
    final slot = MochiButtonMetrics(
      height: m.height,
      horizontalPadding: 0,
      gap: m.gap,
      iconSize: m.iconSize,
      radius: m.radius,
      textStyle: m.textStyle,
    );

    void go(int next) {
      if (next < 1 || next > pages || next == page) return;
      onChanged?.call(next);
    }

    return Semantics(
      container: true,
      label: label ?? "Pagination",
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: g.space.xs3,
        children: [
          if (showArrows)
            MochiButton.icon(
              size: size,
              appearance: MochiButtonAppearance.ghost,
              intent: MochiIntent.neutral,
              enabled: _enabled && page > 1,
              onPress: () => go(page - 1),
              icon: Icon(theme.icons.chevronLeft),
              semanticLabel: "Previous page",
            ),
          for (final at in _slots)
            SizedBox(
              width: side,
              child: at == null
                  ? const _Gap()
                  : MochiButton(
                      metrics: slot,
                      // The page you are on is filled in; the others are quiet until pointed at.
                      appearance: at == page ? MochiButtonAppearance.solid : MochiButtonAppearance.ghost,
                      intent: at == page ? intent : MochiIntent.neutral,
                      enabled: _enabled,
                      onPress: () => go(at),
                      semanticLabel: at == page ? "Page $at, current" : "Page $at",
                      child: Text("$at"),
                    ),
            ),
          if (showArrows)
            MochiButton.icon(
              size: size,
              appearance: MochiButtonAppearance.ghost,
              intent: MochiIntent.neutral,
              enabled: _enabled && page < pages,
              onPress: () => go(page + 1),
              icon: Icon(theme.icons.chevronRight),
              semanticLabel: "Next page",
            ),
        ],
      ),
    );
  }
}

/// The … standing in for the pages a row folded away. Not a button: there is nothing to press,
/// and the neighbouring numbers are how you get there.
class _Gap extends StatelessWidget {
  const _Gap();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return ExcludeSemantics(
      child: Center(
        child: Text("…", style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground)),
      ),
    );
  }
}
