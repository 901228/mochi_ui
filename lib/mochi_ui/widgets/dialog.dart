import "package:flutter/services.dart";
import "package:flutter/widgets.dart";

import "../theme/geometry.dart";
import "../theme/motion.dart";
import "../theme/responsive.dart";
import "../theme/strings.dart";
import "../theme/styles/button_style.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "button.dart";
import "focus_ring.dart";
import "sheet.dart";
import "text_field.dart";
import "tile.dart";
import "transitions.dart";

/// A modal box: a title, some content, and the actions that answer it.
///
/// Show it with [showMochiDialog], which supplies the barrier and the motion.
class MochiDialog extends StatelessWidget {
  const MochiDialog({
    super.key,
    required this.title,
    this.titleSuffix,
    this.body,
    this.actions = const [],
    this.actionsAxis,
    this.constraints = const BoxConstraints(minWidth: 280, maxWidth: 560),
    this.padding,
    this.semanticLabel,
  });

  final Widget title;

  /// At the end of the title's own line: a close button, or an action that belongs to the panel
  /// rather than to the answer — one that changes what is in the modal instead of ending it.
  ///
  /// The actions below are the answers, and a button among them says "this closes the modal";
  /// a phone stacks them full width, where anything else reads as a third way out.
  final Widget? titleSuffix;

  /// The question or detail under the title. Scrolls when it outgrows the screen.
  final Widget? body;

  /// Answers to the dialog, in reading order: the one that dismisses it first, the one that
  /// carries it out last.
  final List<Widget> actions;

  /// Defaults to a column of full-width buttons on touch and a row aligned to the end on the
  /// desktop scale, which is where the pointer already is.
  final Axis? actionsAxis;

  final BoxConstraints constraints;
  final EdgeInsetsGeometry? padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final g = theme.geometry;
    final axis = actionsAxis ?? (theme.touch ? Axis.vertical : Axis.horizontal);

    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      namesRoute: true,
      label: semanticLabel,
      child: ConstrainedBox(
        constraints: constraints,
        child: Container(
          padding: padding ?? EdgeInsets.all(theme.touch ? g.space.lg : g.space.md),
          decoration: ShapeDecoration(
            // The same ground as a popover: a dialog floats above the page rather than being part
            // of it.
            color: colors.overlay,
            shadows: g.shadows.of(MochiElevation.lg, colors.shadow),
            shape: RoundedSuperellipseBorder(
              borderRadius: g.radius.lg,
              side: BorderSide(color: colors.border, width: g.borderWidth),
            ),
          ),
          child: _ModalColumn(
            title: title,
            titleSuffix: titleSuffix,
            body: body,
            actions: actions,
            actionsAxis: axis,
          ),
        ),
      ),
    );
  }
}

/// Title, body and actions, laid out the same way whichever container they end up in.
class _ModalColumn extends StatelessWidget {
  const _ModalColumn({
    required this.title,
    required this.titleSuffix,
    required this.body,
    required this.actions,
    required this.actionsAxis,
  });

  final Widget title;
  final Widget? titleSuffix;
  final Widget? body;
  final List<Widget> actions;
  final Axis actionsAxis;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final g = theme.geometry;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (titleSuffix case final suffix?)
          Row(
            spacing: g.space.sm,
            children: [
              Expanded(
                child: DefaultTextStyle(
                  style: theme.typography.title.md.copyWith(color: colors.foreground),
                  child: title,
                ),
              ),
              suffix,
            ],
          )
        else
          DefaultTextStyle(
            style: theme.typography.title.md.copyWith(color: colors.foreground),
            child: title,
          ),
        if (body case final body?) ...[
          SizedBox(height: g.space.xs),
          Flexible(
            child: SingleChildScrollView(
              child: DefaultTextStyle(
                style: theme.typography.body.sm.copyWith(color: colors.mutedForeground),
                child: body,
              ),
            ),
          ),
        ],
        if (actions.isNotEmpty) ...[
          SizedBox(height: g.space.lg),
          if (actionsAxis == Axis.horizontal)
            Row(mainAxisAlignment: MainAxisAlignment.end, spacing: g.space.xs, children: actions)
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: g.space.xs,
              children: actions,
            ),
        ],
      ],
    );
  }
}

/// The route [showMochiDialog] pushes: a barrier plus a [MochiSurfaceTransition].
///
/// Exposed so a router can create one directly.
class MochiDialogRoute<T> extends PopupRoute<T> {
  MochiDialogRoute({
    required this.builder,
    this.barrierDismissible = true,
    this._barrierLabel,
    this.transition = MochiTransition.scaleFade,
    super.settings,
  });

  final WidgetBuilder builder;
  final MochiTransition transition;

  @override
  final bool barrierDismissible;

  /// Defaults to [MochiStrings.dismiss].
  @override
  String get barrierLabel => _barrierLabel ?? (_theme?.strings ?? MochiStrings.standard).dismiss;
  final String? _barrierLabel;

  // Read from the navigator's context, the same way MochiPageRoute does: the navigator asks for
  // the durations and the barrier before the page is built.
  MochiTheme? get _theme => navigator?.context.getInheritedWidgetOfExactType<MochiThemeScope>()?.theme;

  MochiMotion get _motion => _theme?.motion ?? MochiMotion.standard;

  @override
  Color? get barrierColor {
    final shadow = _theme?.colors.shadow ?? const Color(0xFF000000);
    return shadow.withValues(alpha: shadow.a * 0.5);
  }

  @override
  Duration get transitionDuration => _motion.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _motion.transitionReverseDuration;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondary) {
    final g = context.theme.geometry;
    // The keyboard is padding, not a thing to be covered by: the box centres in the room that is
    // left rather than behind the keys, which is where a dialog with a field in it would sit.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(g.space.lg) + EdgeInsets.only(bottom: keyboard),
        child: builder(context),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => MochiSurfaceTransition(
    animation: animation,
    transition: transition,
    // The barrier does the dimming, over the whole screen rather than the dialog's own box.
    scrim: false,
    child: child,
  );
}

/// Shows [builder]'s widget, usually a [MochiDialog], over the page.
///
/// Returns what the dialog was popped with, or null when it was dismissed by the barrier or
/// Escape.
Future<T?> showMochiDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String? barrierLabel,
  bool useRootNavigator = true,
  RouteSettings? settings,
}) => Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
  MochiDialogRoute<T>(
    builder: builder,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    settings: settings,
  ),
);

/// Which container an adaptive modal ends up in.
enum MochiModalForm {
  /// A box in the middle of the screen.
  dialog,

  /// A panel along the bottom edge, within reach of a thumb.
  sheet,
}

/// Asks something modally, in whichever container suits the screen.
///
/// A dialog on anything tablet-sized and up, a bottom sheet on a phone, where a box in the middle
/// of the screen is out of reach and the actions want to be full width. Pass [form] to settle it
/// either way, or call [showMochiDialog] / [showMochiSheet] directly when the answer is never in
/// doubt.
///
/// [sheetConstraints] is handed to the [MochiSheet] on a phone, where the default cap is half the
/// screen — enough for a question, not for a panel. [titleSuffix] puts something at the end of the
/// title's line, which is where anything that isn't an answer belongs.
///
/// This takes the parts of the question rather than a built widget on purpose: the two containers
/// lay their actions out differently, so there is no one subtree that suits both.
Future<T?> showMochiModal<T>(
  BuildContext context, {
  required Widget title,
  Widget? titleSuffix,
  Widget? body,
  List<Widget> actions = const [],
  MochiModalForm? form,
  BoxConstraints? sheetConstraints,
  bool barrierDismissible = true,
  String? barrierLabel,
  bool useRootNavigator = true,
  RouteSettings? settings,
}) {
  final resolved = form ?? context.responsive<MochiModalForm>(mobile: .sheet, tablet: .dialog);

  return switch (resolved) {
    MochiModalForm.dialog => showMochiDialog<T>(
      context,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      useRootNavigator: useRootNavigator,
      settings: settings,
      builder: (context) => MochiDialog(title: title, titleSuffix: titleSuffix, body: body, actions: actions),
    ),
    MochiModalForm.sheet => showMochiSheet<T>(
      context,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      useRootNavigator: useRootNavigator,
      settings: settings,
      builder: (context) => MochiSheet(
        // A sheet stops at half the screen, which is right for a question and short for a panel:
        // a modal carrying a picker says how much room it needs, and then nothing has to scroll.
        constraints: sheetConstraints,
        child: _ModalColumn(
          title: title,
          titleSuffix: titleSuffix,
          body: body,
          actions: actions,
          actionsAxis: Axis.vertical,
        ),
      ),
    ),
  };
}

/// Asks a yes-or-no question and returns the answer.
///
/// False when the question was dismissed rather than answered, so a caller can act on a plain
/// `if (await showMochiConfirm(...))`. Set [destructive] for something that cannot be undone: the
/// confirming button then carries the danger intent.
///
/// ```dart
/// if (await showMochiConfirm(
///   context,
///   title: "Delete record?",
///   message: "This record will be permanently deleted.",
///   confirmLabel: "Delete",
///   destructive: true,
/// )) {
///   await dao.delete(id);
/// }
/// ```
Future<bool> showMochiConfirm(
  BuildContext context, {
  required String title,
  String? message,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = false,
  MochiModalForm? form,
  bool barrierDismissible = true,
}) async {
  final strings = _stringsOf(context);
  final answer = await showMochiModal<bool>(
    context,
    form: form,
    barrierDismissible: barrierDismissible,
    title: Text(title),
    body: message == null ? null : Text(message),
    actions: [
      MochiModalAction(
        label: cancelLabel ?? strings.cancel,
        appearance: MochiButtonAppearance.outlined,
        value: false,
      ),
      MochiModalAction(
        label: confirmLabel ?? strings.ok,
        intent: destructive ? MochiIntent.danger : null,
        value: true,
      ),
    ],
  );

  return answer ?? false;
}

/// Asks for a line of text — a new name, a comment — and returns it, or null if the question was
/// dismissed.
///
/// [validate] returns an error to show under the field, or null to accept; it runs when the user
/// confirms, not on every keystroke, and the modal stays open until it passes. The field starts
/// focused with its text selected, so a rename can be typed straight over.
///
/// ```dart
/// final name = await showMochiPrompt(
///   context,
///   title: "Rename session",
///   initialValue: session.name,
///   validate: (value) => value.trim().isEmpty ? "A name can't be empty." : null,
/// );
/// ```
Future<String?> showMochiPrompt(
  BuildContext context, {
  required String title,
  String? message,
  String? initialValue,
  String? hint,
  String? confirmLabel,
  String? cancelLabel,
  String? Function(String value)? validate,
  int? maxLength,
  MochiModalForm? form,
  bool barrierDismissible = true,
}) {
  final strings = _stringsOf(context);
  final prompt = _Prompt(initialValue ?? "", validate);

  return showMochiModal<String>(
    context,
    form: form,
    barrierDismissible: barrierDismissible,
    title: Text(title),
    body: _PromptField(prompt: prompt, message: message, hint: hint, maxLength: maxLength),
    actions: [
      MochiModalAction<String>(
        label: cancelLabel ?? strings.cancel,
        appearance: MochiButtonAppearance.outlined,
      ),
      _PromptConfirm(prompt: prompt, label: confirmLabel ?? strings.ok),
    ],
  );
}

/// What the field and the confirm button of a prompt share. The field's state owns the
/// controller, so it lives exactly as long as the route does — through the exit animation, which
/// is still drawing the field after the returned future has completed.
class _Prompt {
  _Prompt(this.initialText, this.validate);

  final String initialText;
  final String? Function(String value)? validate;
  _PromptFieldState? _field;

  /// Pops [context]'s modal with the text, unless [validate] objects.
  void confirm(BuildContext context) {
    final field = _field;
    if (field == null) return;
    final text = field.controller.text;
    final problem = validate?.call(text);
    field.error.value = problem;
    if (problem == null) Navigator.of(context).pop(text);
  }
}

class _PromptField extends StatefulWidget {
  const _PromptField({
    required this.prompt,
    required this.message,
    required this.hint,
    required this.maxLength,
  });

  final _Prompt prompt;
  final String? message;
  final String? hint;
  final int? maxLength;

  @override
  State<_PromptField> createState() => _PromptFieldState();
}

class _PromptFieldState extends State<_PromptField> {
  // Selected, so a rename can be typed straight over.
  late final controller = TextEditingController(text: widget.prompt.initialText)
    ..selection = TextSelection(baseOffset: 0, extentOffset: widget.prompt.initialText.length);
  final error = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();

    widget.prompt._field = this;
  }

  @override
  void dispose() {
    if (widget.prompt._field == this) widget.prompt._field = null;
    controller.dispose();
    error.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    // The modal's body scrolls, and a scroll view clips: leave the field's focus ring room.
    return Padding(
      padding: EdgeInsets.all(MochiFocusRing.outsetOf(context)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: g.space.sm,
        children: [
          if (widget.message case final message?) Text(message),
          ValueListenableBuilder(
            valueListenable: error,
            builder: (context, problem, _) => MochiTextField(
              controller: controller,
              hint: widget.hint,
              error: problem,
              maxLength: widget.maxLength,
              autofocus: true,
              textInputAction: TextInputAction.done,
              // A fresh keystroke clears the complaint about the old text.
              onChanged: (_) => error.value = null,
              onSubmitted: (_) => widget.prompt.confirm(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptConfirm extends StatelessWidget {
  const _PromptConfirm({required this.prompt, required this.label});

  final _Prompt prompt;
  final String label;

  @override
  Widget build(BuildContext context) =>
      MochiButton(onPress: () => prompt.confirm(context), child: Text(label));
}

/// Says something that only needs acknowledging.
Future<void> showMochiAlert(
  BuildContext context, {
  required String title,
  String? message,
  String? dismissLabel,
  MochiIntent? intent,
  MochiModalForm? form,
}) => showMochiModal<void>(
  context,
  form: form,
  title: Text(title),
  body: message == null ? null : Text(message),
  actions: [MochiModalAction(label: dismissLabel ?? _stringsOf(context).ok, intent: intent)],
);

// Helpers run once from an event handler rather than building, and may be called from outside a
// MochiApp, so they read without depending and fall back to the defaults.
MochiStrings _stringsOf(BuildContext context) =>
    MochiTheme.maybeRead(context)?.strings ?? MochiStrings.standard;

/// A button in a modal that pops the modal with [value] when pressed.
///
/// Saves every caller writing the same `Navigator.of(context).pop(...)`, and is what the helpers
/// above are built from.
class MochiModalAction<T> extends StatelessWidget {
  const MochiModalAction({super.key, required this.label, this.value, this.intent, this.appearance});

  final String label;

  /// What the modal is popped with. Null pops with nothing, which is what a plain acknowledgement
  /// wants.
  final T? value;

  final MochiIntent? intent;
  final MochiButtonAppearance? appearance;

  @override
  Widget build(BuildContext context) => MochiButton(
    intent: intent,
    appearance: appearance,
    onPress: () => Navigator.of(context).pop(value),
    child: Text(label),
  );
}

/// One of the options offered by [showMochiChoice].
@immutable
class MochiChoice<T> {
  const MochiChoice({
    required this.value,
    required this.label,
    this.description,
    this.icon,
    this.intent,
    this.enabled = true,
  });

  /// What [showMochiChoice] returns when this option is picked.
  final T value;

  final String label;

  /// A second line under the label.
  final String? description;

  final IconData? icon;

  /// Colours the row when it is the one already chosen, and marks out an option that stands
  /// apart from the rest.
  final MochiIntent? intent;

  final bool enabled;
}

/// Asks which one, and returns it — or null if the question was dismissed.
///
/// Takes the options as data rather than widgets for the same reason [showMochiModal] takes the
/// parts of a question: a dialog and a sheet lay a list out differently.
Future<T?> showMochiChoice<T>(
  BuildContext context, {
  required String title,
  required List<MochiChoice<T>> choices,
  String? message,
  T? selected,
  String? cancelLabel,
  bool cancelable = true,
  MochiModalForm? form,
  bool barrierDismissible = true,
}) => showMochiModal<T>(
  context,
  form: form,
  barrierDismissible: barrierDismissible,
  title: Text(title),
  body: _ChoiceList(choices: choices, selected: selected, message: message),
  actions: [
    if (cancelable)
      MochiModalAction<T>(
        label: cancelLabel ?? _stringsOf(context).cancel,
        appearance: MochiButtonAppearance.outlined,
      ),
  ],
);

class _ChoiceList<T> extends StatelessWidget {
  const _ChoiceList({required this.choices, required this.selected, required this.message});

  final List<MochiChoice<T>> choices;
  final T? selected;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: g.space.sm,
      children: [
        if (message case final message?) Text(message),
        MochiTileGroup(
          reservePrefix: choices.any((choice) => choice.icon != null),
          children: [
            for (final choice in choices)
              MochiTile(
                title: Text(choice.label),
                subtitle: choice.description == null ? null : Text(choice.description!),
                prefix: choice.icon == null ? null : Icon(choice.icon),
                intent: choice.intent ?? MochiIntent.primary,
                enabled: choice.enabled,
                selected: choice.value == selected,
                // The check marks what is already chosen, so the list reads the same whether or
                // not picking one closes it.
                suffix: choice.value == selected ? Icon(theme.icons.check) : null,
                onPress: () => Navigator.of(context).pop(choice.value),
              ),
          ],
        ),
      ],
    );
  }
}
