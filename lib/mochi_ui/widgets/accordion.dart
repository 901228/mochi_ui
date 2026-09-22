import "package:flutter/widgets.dart";

import "../theme/theme.dart";
import "collapsible.dart";
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
/// Uncontrolled from [initiallyExpanded] unless [expanded] is given, the same rule as the
/// collapsible itself.
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
    this.expanded,
    this.initiallyExpanded = const {},
    this.onExpandedChanged,
    this.divider = true,
  });

  final List<MochiAccordionItem> items;

  /// Whether more than one row can be open at a time.
  final bool multiple;

  /// The open rows, by their place in [items]. Non-null takes ownership: the accordion then only
  /// reports what was asked for.
  final Set<int>? expanded;

  /// Where an uncontrolled accordion starts.
  final Set<int> initiallyExpanded;

  /// Called with the whole new set of open rows.
  final ValueChanged<Set<int>>? onExpandedChanged;

  /// Lines between the rows, and under the last one's header while it is open.
  final bool divider;

  @override
  State<MochiAccordion> createState() => _MochiAccordionState();
}

class _MochiAccordionState extends State<MochiAccordion> {
  late final Set<int> _own = {...widget.initiallyExpanded};

  Set<int> get _expanded => widget.expanded ?? _own;

  void _toggle(int index, bool open) {
    final next = switch ((open, widget.multiple)) {
      // One at a time: opening a row is also the way the one before it closes.
      (true, false) => {index},
      (true, true) => {..._expanded, index},
      (false, _) => {..._expanded}..remove(index),
    };

    widget.onExpandedChanged?.call(next);
    if (widget.expanded != null) return;
    setState(() {
      _own
        ..clear()
        ..addAll(next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, item) in widget.items.indexed) ...[
          if (index > 0 && widget.divider) const MochiDivider(),
          // A margin around each row, so the header's hover fill stops short of the line between
          // them instead of running into it.
          Padding(
            padding: EdgeInsets.symmetric(vertical: g.space.xs2),
            child: MochiCollapsible(
              // The heading typeface, not a bolder body one: Comfortaa's 600 next to its 400 is
              // a whisper at this size, and `title` is the weight this system reserves for
              // headings anyway.
              title: DefaultTextStyle.merge(style: theme.typography.title.md, child: item.title),
              enabled: item.enabled,
              expanded: _expanded.contains(index),
              onExpandedChanged: (open) => _toggle(index, open),
              headerPadding: EdgeInsets.symmetric(horizontal: g.space.xs, vertical: g.space.xs),
              bodyPadding: EdgeInsets.only(left: g.space.xs, right: g.space.xs, top: g.space.xs3),
              radius: g.radius.sm,
              child: item.child,
            ),
          ),
        ],
      ],
    );
  }
}
