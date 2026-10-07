import "dart:math" as math;

import "package:flutter/services.dart";
import "package:flutter/widgets.dart";

import "../theme/colors.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "../theme/typography.dart";
import "focus_ring.dart";
import "state_transition.dart";
import "tappable.dart";
import "value_transition.dart";

/// A node in a [MochiTree].
class MochiTreeNode<T> {
  const MochiTreeNode({
    required this.value,
    required this.label,
    this.icon,
    this.trailing,
    this.children = const [],
    this.enabled = true,
  });

  /// Identifies the node: what selection and expansion are keyed by, so it has to be unique
  /// across the tree and stable between builds.
  final T value;

  final Widget label;

  /// Before the label, after the chevron.
  final Widget? icon;

  /// At the end of the row: a count, a badge.
  final Widget? trailing;

  final List<MochiTreeNode<T>> children;
  final bool enabled;

  bool get hasChildren => children.isNotEmpty;
}

/// A tree of nodes that open and close: a folder of sessions, a scramble broken into its parts.
///
/// Rows are indented by depth with a line down each level that still has something below it, so
/// a deep tree stays readable. The keyboard walks it the way a tree is walked: up and down move
/// between the rows that are showing, right opens a node or steps into it, left closes it or
/// steps back out to its parent.
///
/// Expansion is uncontrolled from [initiallyExpanded] unless [expanded] is given, the same rule
/// as [MochiCollapsible]. Selection is always the app's.
class MochiTree<T extends Object> extends StatefulWidget {
  const MochiTree({
    super.key,
    required this.nodes,
    this.selected,
    this.onSelected,
    this.expanded,
    this.onExpandedChanged,
    this.initiallyExpanded = const {},
    this.indent = 16,
    this.showLines = true,
    this.intent = MochiIntent.primary,
  });

  final List<MochiTreeNode<T>> nodes;

  /// The chosen node's value, or null for none.
  final T? selected;

  /// Called when a row is pressed or activated from the keyboard.
  final ValueChanged<T>? onSelected;

  /// The open nodes. Non-null takes ownership: the tree then only reports what was asked for.
  final Set<T>? expanded;

  /// Called with the node and whether it was opened.
  final void Function(T value, bool expanded)? onExpandedChanged;

  /// Where an uncontrolled tree starts.
  final Set<T> initiallyExpanded;

  /// How far each level is indented.
  final double indent;

  /// The lines down the indents. Off leaves plain space.
  final bool showLines;

  final MochiIntent intent;

  @override
  State<MochiTree<T>> createState() => _MochiTreeState<T>();
}

class _MochiTreeState<T extends Object> extends State<MochiTree<T>> {
  late final Set<T> _open = {...widget.initiallyExpanded};

  /// One per row, kept by value so a row keeps its focus as the tree above it opens and closes.
  final _focusNodes = <T, FocusNode>{};

  /// The row the keyboard is on, so the arrows know where they are.
  T? _focused;

  Set<T> get _expanded => widget.expanded ?? _open;

  @override
  void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }

    super.dispose();
  }

  FocusNode _focusNodeFor(T value) => _focusNodes.putIfAbsent(value, FocusNode.new);

  void _toggle(T value, {bool? open}) {
    final next = open ?? !_expanded.contains(value);
    if (next == _expanded.contains(value)) return;

    widget.onExpandedChanged?.call(value, next);
    if (widget.expanded != null) return;
    setState(() => next ? _open.add(value) : _open.remove(value));
  }

  /// The rows showing right now, in the order they are drawn.
  List<_Row<T>> get _rows {
    final rows = <_Row<T>>[];

    void walk(List<MochiTreeNode<T>> nodes, int depth, List<bool> lines, T? parent) {
      for (final (index, node) in nodes.indexed) {
        final last = index == nodes.length - 1;
        rows.add(
          _Row(
            node: node,
            depth: depth,
            // A line is drawn at each level above that still has a sibling waiting below it.
            lines: [...lines, !last],
            parent: parent,
            expanded: _expanded.contains(node.value),
          ),
        );
        if (node.hasChildren && _expanded.contains(node.value)) {
          walk(node.children, depth + 1, [...lines, !last], node.value);
        }
      }
    }

    walk(widget.nodes, 0, const [], null);
    return rows;
  }

  void _move(int direction) {
    final rows = _rows;
    final at = rows.indexWhere((row) => row.node.value == _focused);
    final next = at < 0 ? (direction > 0 ? 0 : rows.length - 1) : at + direction;
    if (next < 0 || next >= rows.length) return;
    _focusNodeFor(rows[next].node.value).requestFocus();
  }

  void _out() {
    final rows = _rows;
    final row = rows.where((row) => row.node.value == _focused).firstOrNull;
    if (row == null) return;
    // An open node closes; a closed one hands the keyboard back to its parent.
    if (row.node.hasChildren && row.expanded) return _toggle(row.node.value, open: false);
    if (row.parent case final parent?) _focusNodeFor(parent).requestFocus();
  }

  void _into() {
    final rows = _rows;
    final row = rows.where((row) => row.node.value == _focused).firstOrNull;
    if (row == null || !row.node.hasChildren) return;
    if (!row.expanded) return _toggle(row.node.value, open: true);
    _move(1);
  }

  void _end({required bool last}) {
    final rows = _rows;
    if (rows.isEmpty) return;
    _focusNodeFor(rows[last ? rows.length - 1 : 0].node.value).requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowDown): _MoveIntent(1),
        SingleActivator(LogicalKeyboardKey.arrowUp): _MoveIntent(-1),
        SingleActivator(LogicalKeyboardKey.arrowRight): _LevelIntent(into: true),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _LevelIntent(into: false),
        SingleActivator(LogicalKeyboardKey.home): _EdgeIntent(last: false),
        SingleActivator(LogicalKeyboardKey.end): _EdgeIntent(last: true),
      },
      child: Actions(
        actions: {
          _MoveIntent: CallbackAction<_MoveIntent>(onInvoke: (intent) => _move(intent.direction)),
          _LevelIntent: CallbackAction<_LevelIntent>(
            // Right steps in the way the text runs, so in right-to-left it is left that does.
            onInvoke: (intent) => intent.into == !rtl ? _into() : _out(),
          ),
          _EdgeIntent: CallbackAction<_EdgeIntent>(onInvoke: (intent) => _end(last: intent.last)),
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final row in _rows)
              _TreeRow<T>(
                key: ValueKey(row.node.value),
                row: row,
                indent: widget.indent,
                showLines: widget.showLines,
                intent: widget.intent,
                selected: row.node.value == widget.selected,
                focusNode: _focusNodeFor(row.node.value),
                onFocusChange: (focused) {
                  if (focused) _focused = row.node.value;
                },
                onPress: () {
                  widget.onSelected?.call(row.node.value);
                  // A parent row is also the way to open it: the chevron is small, and the row
                  // is what the pointer is already on.
                  if (row.node.hasChildren) _toggle(row.node.value);
                },
                onToggle: row.node.hasChildren ? () => _toggle(row.node.value) : null,
              ),
          ],
        ),
      ),
    );
  }
}

/// A row as it is drawn: which node, how deep, and which indents still carry a line.
@immutable
class _Row<T> {
  const _Row({
    required this.node,
    required this.depth,
    required this.lines,
    required this.parent,
    required this.expanded,
  });

  final MochiTreeNode<T> node;
  final int depth;

  /// One per level down to this row: whether that level still has a sibling below.
  final List<bool> lines;
  final T? parent;
  final bool expanded;
}

class _TreeRow<T extends Object> extends StatelessWidget {
  const _TreeRow({
    super.key,
    required this.row,
    required this.indent,
    required this.showLines,
    required this.intent,
    required this.selected,
    required this.focusNode,
    required this.onFocusChange,
    required this.onPress,
    required this.onToggle,
  });

  final _Row<T> row;
  final double indent;
  final bool showLines;
  final MochiIntent intent;
  final bool selected;
  final FocusNode focusNode;
  final ValueChanged<bool> onFocusChange;
  final VoidCallback onPress;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final g = theme.geometry;
    final tone = colors.of(intent);
    final height = (theme.touch ? 36.0 : 28.0) * theme.density;
    final iconSize = theme.touch ? 18.0 : 16.0;

    return MochiTappable(
      enabled: row.node.enabled,
      selected: selected,
      focusNode: focusNode,
      onFocusChange: onFocusChange,
      // A row in a list: it tints rather than growing.
      scaleOnPress: false,
      onPress: onPress,
      builder: (context, states, _) => MochiStateTransition(
        states: states,
        duration: theme.motion.stateDuration,
        builder: (context, blend) {
          final foreground = blend.color(
            (st) => st.contains(WidgetState.selected) ? tone.onSoft : colors.foreground,
          );

          return MochiFocusRing(
            visible: blend.contains(WidgetState.focused),
            radius: g.radius.xs,
            inset: true,
            child: Opacity(
              opacity: blend.contains(WidgetState.disabled) ? 0.4 : 1,
              child: Container(
                height: height,
                decoration: ShapeDecoration(
                  color: blend.color(
                    (st) => st.contains(WidgetState.selected)
                        ? MochiColors.stateLayer(colors.softOn(tone, colors.surface), tone.onSoft, st)
                        : MochiColors.stateLayer(colors.surface.withValues(alpha: 0), colors.foreground, st),
                  ),
                  shape: g.shape(borderRadius: g.radius.xs),
                ),
                child: IconTheme.merge(
                  data: IconThemeData(color: foreground, size: iconSize),
                  child: DefaultTextStyle(
                    style: theme.typography.body.sm
                        .withWeight(selected ? FontWeight.w600 : FontWeight.w400)
                        .copyWith(color: foreground),
                    child: Row(
                      children: [
                        // One indent per level above this row, each with the line that says
                        // whether that level goes on below.
                        for (final line in row.lines.take(row.depth))
                          _Indent(width: indent, line: showLines && line, color: colors.border),
                        SizedBox(
                          width: indent + g.space.xs3,
                          child: onToggle == null
                              // A leaf keeps the chevron's room, so its label lines up with its
                              // siblings' rather than sliding under them.
                              ? const SizedBox.shrink()
                              : _Chevron(expanded: row.expanded, onPress: onToggle!, size: iconSize),
                        ),
                        if (row.node.icon case final icon?) ...[icon, SizedBox(width: g.space.xs2)],
                        Expanded(
                          child: DefaultTextStyle.merge(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            child: row.node.label,
                          ),
                        ),
                        if (row.node.trailing case final trailing?)
                          Padding(
                            padding: EdgeInsetsDirectional.only(start: g.space.xs2, end: g.space.xs2),
                            child: trailing,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One level of indent, with the line that carries on down past this row.
class _Indent extends StatelessWidget {
  const _Indent({required this.width, required this.line, required this.color});

  final double width;
  final bool line;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: line
        ? Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: EdgeInsetsDirectional.only(start: width / 2),
              child: SizedBox(
                width: 1,
                height: double.infinity,
                child: ColoredBox(color: color),
              ),
            ),
          )
        : null,
  );
}

/// The triangle that opens a node. Its own target, so the row can mean "choose this" as well.
class _Chevron extends StatelessWidget {
  const _Chevron({required this.expanded, required this.onPress, required this.size});

  final bool expanded;
  final VoidCallback onPress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return MochiTappable(
      onPress: onPress,
      scaleOnPress: false,
      semanticLabel: expanded ? theme.strings.collapse : theme.strings.expand,
      // The row takes the keyboard; the chevron is for the pointer.
      builder: (context, states, _) => ExcludeFocus(
        child: Center(
          // The same turn a collapsible's chevron makes, through the same transition: an
          // implicit AnimatedRotation would restart on every frame of a theme change.
          child: MochiValueTransition<double>(
            value: expanded ? 0.25 : 0,
            lerp: _turns,
            duration: theme.motion.stateDuration,
            builder: (context, turns, child) => Transform.rotate(angle: turns * 2 * math.pi, child: child),
            child: Icon(theme.icons.chevronRight, size: size),
          ),
        ),
      ),
    );
  }
}

class _MoveIntent extends Intent {
  const _MoveIntent(this.direction);

  final int direction;
}

class _LevelIntent extends Intent {
  const _LevelIntent({required this.into});

  final bool into;
}

class _EdgeIntent extends Intent {
  const _EdgeIntent({required this.last});

  final bool last;
}

/// Between two quarter turns.
double _turns(double a, double b, double t) => a + (b - a) * t;
