import "dart:async";

import "package:flutter/services.dart";
import "package:flutter/widgets.dart";

import "../theme/size.dart";
import "../theme/theme.dart";
import "field_frame.dart";
import "menu.dart";
import "popover.dart";
import "text_field.dart";

/// Builds a row for one option, in place of its plain label.
typedef MochiAutocompleteOptionBuilder<T extends Object> = Widget Function(BuildContext context, T option);

/// A text field that suggests what is being typed: a session to move a solve to, a puzzle.
///
/// A [MochiTextField] with a list of matching options under it, as wide as the field. Unlike a
/// [MochiSelect] the text is what counts — the options only help write it — so anything can be
/// typed and [onChanged] reports every keystroke, while [onSelected] fires when one of the
/// options is taken.
///
/// [optionsBuilder] is asked for the options on every keystroke and may return a future, so the
/// suggestions can come from a database or the network. The list appears while the field has
/// focus and there is at least one option. Up and down move through it, Enter takes the
/// highlighted one, and Escape puts the list away.
///
/// ```dart
/// MochiAutocomplete<String>(
///   hint: "Session",
///   optionsBuilder: (value) =>
///       sessions.where((s) => s.toLowerCase().contains(value.text.toLowerCase())),
///   onSelected: (session) => move(solve, session),
/// )
/// ```
class MochiAutocomplete<T extends Object> extends StatelessWidget {
  const MochiAutocomplete({
    super.key,
    required this.optionsBuilder,
    this.onSelected,
    this.displayStringForOption = RawAutocomplete.defaultStringForOption,
    this.optionBuilder,
    this.controller,
    this.focusNode,
    this.initialValue,
    this.label,
    this.hint,
    this.description,
    this.error,
    this.prefix,
    this.suffix,
    this.clearable = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.size = MochiSize.md,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.maxListHeight = 320,
  }) : assert(controller == null || initialValue == null, "Pass the text in the controller instead.");

  /// The options matching what has been typed, in the order they are shown. May return a future.
  final FutureOr<Iterable<T>> Function(TextEditingValue value) optionsBuilder;

  /// Called when an option is taken from the list, by a press or by Enter.
  final ValueChanged<T>? onSelected;

  /// The text an option puts in the field, and its label in the list.
  final String Function(T option) displayStringForOption;

  /// Builds an option's row content, for a suggestion that is more than its text.
  final MochiAutocompleteOptionBuilder<T>? optionBuilder;

  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// The starting text when the field owns its controller.
  final String? initialValue;

  final Widget? label;
  final String? hint;
  final Widget? description;
  final String? error;
  final Widget? prefix;
  final Widget? suffix;
  final bool clearable;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  /// Its own limits go here; there is no `maxLength`, whose counter would sit between the box
  /// and the list.
  final List<TextInputFormatter>? inputFormatters;
  final MochiSize size;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// The list scrolls past this height. It never grows past the room under the field either.
  final double maxListHeight;

  @override
  Widget build(BuildContext context) {
    // The frame is outside the autocomplete, not around the field it builds: the list is placed
    // under the whole field view, which would be under the description and the counter too.
    return MochiFieldFrame(
      label: label,
      description: description,
      error: error,
      enabled: enabled,
      child: RawAutocomplete<T>(
        optionsBuilder: optionsBuilder,
        onSelected: onSelected,
        displayStringForOption: displayStringForOption,
        textEditingController: controller,
        focusNode: focusNode,
        initialValue: initialValue == null ? null : TextEditingValue(text: initialValue!),
        optionsViewBuilder: (context, onSelected, options) => _Options<T>(
          options: options.toList(),
          onSelected: onSelected,
          displayStringForOption: displayStringForOption,
          optionBuilder: optionBuilder,
          maxHeight: maxListHeight,
        ),
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) => MochiTextField(
          controller: controller,
          focusNode: focusNode,
          hint: hint,
          prefix: prefix,
          suffix: suffix,
          clearable: clearable,
          enabled: enabled,
          readOnly: readOnly,
          autofocus: autofocus,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          size: size,
          autofillHints: autofillHints,
          onChanged: onChanged,
          onSubmitted: (text) {
            // Takes the highlighted option, if the list is showing; the field's own handler runs
            // either way, since Enter is still Enter.
            onFieldSubmitted();
            onSubmitted?.call(text);
          },
        ),
      ),
    );
  }
}

/// The list under the field: the same panel and rows as a menu, with the row the arrows are on
/// marked the way a chosen one is.
class _Options<T extends Object> extends StatefulWidget {
  const _Options({
    required this.options,
    required this.onSelected,
    required this.displayStringForOption,
    required this.optionBuilder,
    required this.maxHeight,
  });

  final List<T> options;
  final AutocompleteOnSelected<T> onSelected;
  final String Function(T option) displayStringForOption;
  final MochiAutocompleteOptionBuilder<T>? optionBuilder;
  final double maxHeight;

  @override
  State<_Options<T>> createState() => _OptionsState<T>();
}

class _OptionsState<T extends Object> extends State<_Options<T>> {
  final _rowKeys = <int, GlobalKey>{};
  int? _shown;

  GlobalKey _keyFor(int index) => _rowKeys.putIfAbsent(index, GlobalKey.new);

  /// Keeps the highlighted row in view as the arrows walk past the end of the panel.
  void _follow(int highlighted) {
    if (highlighted == _shown) return;
    _shown = highlighted;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _rowKeys[highlighted]?.currentContext;
      if (context != null && context.mounted) {
        Scrollable.ensureVisible(context, alignmentPolicy: .keepVisibleAtEnd);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;
    // An InheritedNotifier: this rebuilds as the arrows move the highlight.
    final highlighted = AutocompleteHighlightedOption.of(context);
    _follow(highlighted);

    return Padding(
      // Clear of the field, as a popover is of its anchor.
      padding: EdgeInsets.only(top: g.space.xs2),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: widget.maxHeight),
          // The panel is handed the field's width as a maximum and the room below as a height,
          // both loose: it fills the width and keeps only the height its rows need.
          child: SizedBox(
            width: double.infinity,
            child: MochiPopoverSurface(
              padding: EdgeInsets.all(g.space.xs2),
              child: MochiMenu(
                minWidth: 0,
                children: [
                  for (final (index, option) in widget.options.indexed)
                    MochiMenuItem(
                      key: _keyFor(index),
                      title:
                          widget.optionBuilder?.call(context, option) ??
                          Text(widget.displayStringForOption(option)),
                      // The row Enter would take, marked as a chosen one is.
                      selected: index == highlighted,
                      onPress: () => widget.onSelected(option),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
