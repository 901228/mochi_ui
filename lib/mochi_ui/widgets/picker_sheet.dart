import "package:flutter/widgets.dart";

import "../theme/theme.dart";
import "../theme/tone.dart";
import "button.dart";
import "sheet.dart";

/// Shows a picker's panel in a sheet, with a draft of its own and a button that keeps it.
///
/// A sheet is a route, and a route builds its page once: the picker's own `setState` never
/// reaches back inside it, so a calendar pushed in there would go on showing the day it was
/// pushed with and a range could never be given its second end. The draft lives in the sheet
/// instead — which is also what a sheet is for. A popover is a thing you glance at and dismiss,
/// so it reports every press as it happens; a sheet covers the page and is answered, so nothing
/// leaves it until the button says so. Dragging it away or pressing the barrier drops the draft.
///
/// Completes with the draft, or null when it was dismissed instead of confirmed.
Future<T?> showPickerSheet<T>(
  BuildContext context, {
  required T initial,
  required Widget Function(BuildContext context, T value, ValueChanged<T> onChanged) body,
  bool Function(T value)? answered,
  MochiIntent intent = MochiIntent.primary,
}) => showMochiSheet<T>(
  context,
  builder: (context) => _PickerSheet<T>(initial: initial, body: body, answered: answered, intent: intent),
);

class _PickerSheet<T> extends StatefulWidget {
  const _PickerSheet({
    required this.initial,
    required this.body,
    required this.answered,
    required this.intent,
  });

  final T initial;
  final Widget Function(BuildContext context, T value, ValueChanged<T> onChanged) body;

  /// Whether the draft is an answer yet: half a range is not one, and neither is no day at all.
  final bool Function(T value)? answered;

  final MochiIntent intent;

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  late T _draft = widget.initial;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;
    final done = widget.answered?.call(_draft) ?? true;

    return MochiSheet(
      // A sheet stops at half the screen by default, which a calendar — let alone a calendar over
      // a set of wheels — is taller than.
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      padding: EdgeInsets.all(g.space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The panel scrolls and the button doesn't: what keeps the answer should not be the
          // thing a short screen pushes out of sight.
          Flexible(
            child: SingleChildScrollView(
              child: widget.body(context, _draft, (value) => setState(() => _draft = value)),
            ),
          ),
          SizedBox(height: g.space.sm),
          SizedBox(
            width: double.infinity,
            child: MochiButton(
              intent: widget.intent,
              onPress: done ? () => Navigator.of(context).pop(_draft) : null,
              child: Text(theme.strings.ok),
            ),
          ),
        ],
      ),
    );
  }
}
