import "package:flutter/widgets.dart";

/// Who holds a widget's state: the app ([MochiControl.lifted]) or the widget itself
/// ([MochiControl.managed]). Only widgets that can work either way take one — a collapsible, a
/// sidebar that narrows to a rail. A widget whose value is always the app's (a switch, a select)
/// takes a `value` and an `onChanged` instead, as Flutter's own do.
///
/// ```dart
/// MochiSidebar(control: const .managed())                               // the sidebar keeps it
/// MochiSidebar(control: .lifted(value: railed, onChanged: (v) => setState(() => railed = v)))
/// ```
///
/// The names are forui's: "lifted" as in lifting state up, out of the widget into the app.
sealed class MochiControl<T> {
  const MochiControl();

  /// The app holds the value and rebuilds the widget with a new one: [onChanged] only *asks* for
  /// a change, and nothing moves until the app answers. Use it when something else reads or sets
  /// the value too — a setting that is saved, a button elsewhere that does the same thing.
  const factory MochiControl.lifted({required T value, required ValueChanged<T> onChanged}) = MochiLifted<T>;

  /// The widget holds the value itself, starting from [initial] (the widget's own default when
  /// null), and tells [onChanged] what it became.
  const factory MochiControl.managed({T? initial, ValueChanged<T>? onChanged}) = MochiManaged<T>;

  ValueChanged<T>? get onChanged;
}

final class MochiLifted<T> extends MochiControl<T> {
  const MochiLifted({required this.value, required this.onChanged});

  final T value;

  @override
  final ValueChanged<T> onChanged;
}

final class MochiManaged<T> extends MochiControl<T> {
  const MochiManaged({this.initial, this.onChanged});

  final T? initial;

  @override
  final ValueChanged<T>? onChanged;
}

/// The value a [MochiControl] stands for, held in a widget's [State]: read [value], change it with
/// [change]. Not exported — the bookkeeping every controllable widget would otherwise repeat.
class ControlledValue<T> {
  ControlledValue(MochiControl<T> control, T fallback)
    : _own = switch (control) {
        MochiLifted(:final value) => value,
        MochiManaged(:final initial) => initial ?? fallback,
      };

  T _own;

  T value(MochiControl<T> control) => switch (control) {
    MochiLifted(:final value) => value,
    MochiManaged() => _own,
  };

  /// Moves a managed value to [next] through [setState] and reports it; a lifted one is only
  /// reported, since it is the app's to move.
  void change(MochiControl<T> control, T next, void Function(VoidCallback) setState) {
    if (control is MochiManaged<T>) setState(() => _own = next);
    control.onChanged?.call(next);
  }

  /// Keeps the last value the app gave when it hands the state back to the widget, so letting go
  /// does not snap it back to where it started.
  void update(MochiControl<T> old, MochiControl<T> control) {
    if (old case MochiLifted(:final value) when control is MochiManaged<T>) _own = value;
  }
}
