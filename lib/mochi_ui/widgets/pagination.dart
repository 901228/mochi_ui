import "package:flutter/widgets.dart";

import "../theme/size.dart";
import "../theme/styles/button_style.dart";
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

  /// The pages to write out, with nulls where a gap was folded away.
  List<int?> get _slots {
    final first = 1;
    final last = pages;
    final wanted = <int>{
      first,
      last,
      for (var p = page - around; p <= page + around; p++)
        if (p >= first && p <= last) p,
    }.toList()..sort();

    final slots = <int?>[];
    for (final (index, p) in wanted.indexed) {
      final missing = index == 0 ? 0 : p - wanted[index - 1] - 1;
      // One page missing is written out: a … takes the same room as the number it hides, and
      // hiding a single page is only a step someone now can't take.
      if (missing == 1) slots.add(p - 1);
      if (missing > 1) slots.add(null);
      slots.add(p);
    }

    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;

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
          for (final slot in _slots)
            if (slot == null)
              const _Gap()
            else
              MochiButton(
                size: size,
                // The page you are on is filled in; the others are quiet until pointed at.
                appearance: slot == page ? MochiButtonAppearance.solid : MochiButtonAppearance.ghost,
                intent: slot == page ? intent : MochiIntent.neutral,
                enabled: _enabled,
                onPress: () => go(slot),
                semanticLabel: slot == page ? "Page $slot, current" : "Page $slot",
                child: Text("$slot"),
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
      child: SizedBox(
        width: theme.touch ? 24 : 20,
        child: Center(
          child: Text("…", style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground)),
        ),
      ),
    );
  }
}
