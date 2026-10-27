import "package:flutter/widgets.dart";

import "../theme/theme.dart";
import "collapsible.dart";
import "control.dart";
import "divider.dart";

/// One row of a [MochiAccordion].
class MochiAccordionItem {
  const MochiAccordionItem({required this.title, required this.child, this.enabled = true});

  /// The header's label.
  final Widget title;

  /// What opens under it.
  final Widget child;

  final bool enabled;
}

/// A stack of things that open under their own headings: a page of questions and answers, the
/// settings of a session grouped by what they are for.
///
/// Every row is a [MochiCollapsible] — the one way things open and close here — and the accordion
/// only decides which of them are open. With [multiple] off, opening one closes the rest; with it
/// on they are independent.
///
/// Which rows are open is [expanded], a [MochiControl] like the collapsible's own: the accordion
/// keeps it by default, all shut (`.managed(initial: {0})` opens the first).

///
/// ```dart
/// MochiAccordion(
///   items: [
///     MochiAccordionItem(title: const Text("Inspection"), child: inspectionSettings),
///     MochiAccordionItem(title: const Text("Display"), child: displaySettings),
///   ],
/// )
/// ```
class MochiAccordion extends StatefulWidget {
  const MochiAccordion({
    super.key,
    required this.items,
    this.multiple = false,
    this.expanded = const MochiControl.managed(),
    this.divider = true,
    this.spacing,
    this.contentSpacing,
  });

  final List<MochiAccordionItem> items;

  /// Whether more than one row can be open at a time.
  final bool multiple;

  /// The open rows, by their place in [items], and who holds them. `onChanged` is given the whole
  /// new set.
  final MochiControl<Set<int>> expanded;

  /// Lines between the rows, and under the last one's header while it is open.
  final bool divider;

  /// Distance between two rows, divider included. Not applied above the first row or below the last.
  /// Defaults to `geometry.space.xs2`.
  final double? spacing;

  /// Distance between a row's header and its expanded content. Defaults to `geometry.space.xs3`.
  final double? contentSpacing;

  @override
  State<MochiAccordion> createState() => _MochiAccordionState();
}

class _MochiAccordionState extends State<MochiAccordion> {
  late final _value = ControlledValue<Set<int>>(widget.expanded, const {});

  Set<int> get _expanded => _value.value(widget.expanded);

  @override
  void didUpdateWidget(MochiAccordion old) {
    super.didUpdateWidget(old);
    _value.update(old.expanded, widget.expanded);
  }

  void _toggle(int index, bool open) {
    final next = switch ((open, widget.multiple)) {
      // One at a time: opening a row is also the way the one before it closes.
      (true, false) => {index},
      (true, true) => {..._expanded, index},
      (false, _) => {..._expanded}..remove(index),
    };

    _value.change(widget.expanded, next, setState);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;
    final rowSpacing = widget.spacing ?? g.space.xs2;
    final bodySpacing = widget.contentSpacing ?? g.space.xs3;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, item) in widget.items.indexed) ...[
          if (index > 0 && widget.divider) const MochiDivider(),
          // A margin around each row, so the header's hover fill stops short of the line between
          // them instead of running into it.
          Padding(
            // Half each side, so two rows stand [spacing] apart and the ends are left to the
            // accordion's own padding.
            padding: EdgeInsets.only(
              top: index > 0 ? rowSpacing / 2 : 0,
              bottom: index < widget.items.length - 1 ? rowSpacing / 2 : 0,
            ),
            child: MochiCollapsible(
              // The heading typeface, not a bolder body one: Comfortaa's 600 next to its 400 is
              // a whisper at this size, and `title` is the weight this system reserves for
              // headings anyway.
              title: DefaultTextStyle.merge(style: theme.typography.title.md, child: item.title),
              enabled: item.enabled,
              expanded: .lifted(value: _expanded.contains(index), onChanged: (open) => _toggle(index, open)),
              headerPadding: EdgeInsets.symmetric(horizontal: g.space.xs, vertical: g.space.xs),
              bodyPadding: EdgeInsets.only(left: g.space.xs, right: g.space.xs, top: bodySpacing),
              radius: g.radius.sm,
              child: item.child,
            ),
          ),
        ],
      ],
    );
  }
}
