import "dart:async";

import "package:flutter/services.dart";
import "package:flutter/widgets.dart";

import "../theme/size.dart";
import "../theme/theme.dart";
import "circular_progress.dart";
import "text_field.dart";

/// A field for searching: the magnifier, a × once there is something to clear, and a [debounce]
/// so the search itself doesn't run on every keystroke.
///
/// [onChanged] fires as the text changes; [onSearch] fires once the typing stops for [debounce],
/// and at once on submit or on a clear — which is what a query over a list or the network wants
/// to be told. Pass [loading] while that search runs to put a spinner where the × goes.
///
/// For a field that suggests as it goes, use [MochiAutocomplete] with a magnifier as its prefix:
/// suggestions are a list under the field, not a different field.
///
/// ```dart
/// MochiSearchBar(onSearch: (query) => setState(() => _results = search(query)))
/// ```
class MochiSearchBar extends StatefulWidget {
  const MochiSearchBar({
    super.key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.hint,
    this.label,
    this.description,
    this.error,
    this.suffix,
    this.loading = false,
    this.enabled = true,
    this.autofocus = false,
    this.size = MochiSize.md,
    this.debounce = const Duration(milliseconds: 300),
    this.onChanged,
    this.onSearch,
    this.onSubmitted,
  }) : assert(controller == null || initialValue == null, "Pass the text in the controller instead.");

  final TextEditingController? controller;

  /// The starting query when the bar owns its controller.
  final String? initialValue;

  final FocusNode? focusNode;

  /// Defaults to `strings.search`.
  final String? hint;

  final Widget? label;
  final Widget? description;
  final String? error;

  /// After the × , such as a filter button.
  final Widget? suffix;

  /// Shows a spinner in place of the ×, for a search that is still running.
  final bool loading;

  final bool enabled;
  final bool autofocus;
  final MochiSize size;

  /// How long the typing has to stop before [onSearch] runs. [Duration.zero] runs it with every
  /// keystroke.
  final Duration debounce;

  /// Every keystroke.
  final ValueChanged<String>? onChanged;

  /// The query to actually search for: after [debounce], or at once on submit or clear.
  final ValueChanged<String>? onSearch;

  /// Enter. [onSearch] has already run with the same text by then.
  final ValueChanged<String>? onSubmitted;

  @override
  State<MochiSearchBar> createState() => _MochiSearchBarState();
}

class _MochiSearchBarState extends State<MochiSearchBar> {
  TextEditingController? _ownController;
  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController(text: widget.initialValue));

  Timer? _debounce;

  // What onSearch was last told, so a submit or a settled timer doesn't ask for the same query
  // twice.
  String? _searched;

  @override
  void initState() {
    super.initState();

    _searched = _controller.text;
  }

  @override
  void didUpdateWidget(MochiSearchBar old) {
    super.didUpdateWidget(old);

    if (widget.controller != old.controller && widget.controller != null) {
      _ownController?.dispose();
      _ownController = null;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ownController?.dispose();

    super.dispose();
  }

  void _search(String text) {
    _debounce?.cancel();
    _debounce = null;
    if (text == _searched) return;
    _searched = text;
    widget.onSearch?.call(text);
  }

  void _handleChanged(String text) {
    widget.onChanged?.call(text);
    if (widget.debounce == Duration.zero) return _search(text);

    // An emptied field searches at once: waiting to show everything again only looks slow.
    if (text.isEmpty) return _search(text);

    _debounce?.cancel();
    _debounce = Timer(widget.debounce, () => _search(text));
  }

  void _handleSubmitted(String text) {
    _search(text);
    widget.onSubmitted?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;
    // While a search runs the spinner stands where the × would, so the row doesn't shuffle.
    final spinner = widget.loading
        ? MochiCircularProgress(size: widget.size == MochiSize.lg ? MochiSize.sm : MochiSize.xs)
        : null;
    final suffix = widget.suffix;

    return MochiTextField(
      controller: _controller,
      focusNode: widget.focusNode,
      label: widget.label,
      hint: widget.hint ?? theme.strings.search,
      description: widget.description,
      error: widget.error,
      prefix: Icon(theme.icons.search),
      suffix: spinner == null && suffix == null
          ? null
          : Row(mainAxisSize: MainAxisSize.min, spacing: g.space.xs, children: [?spinner, ?suffix]),
      clearable: !widget.loading,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      size: widget.size,
      textInputAction: TextInputAction.search,
      onChanged: _handleChanged,
      onSubmitted: _handleSubmitted,
    );
  }
}
