import "package:flutter/foundation.dart";

import "icons.dart";

/// The handful of words components say themselves, so an app can put them in its own language.
/// Labels an app passes in are its own business, the same rule as [MochiIcons].
///
/// Not a `LocalizationsDelegate`: an app picks one of these for its locale and hands it to
/// `MochiApp(strings:)`.
///
/// ```dart
/// MochiApp(
///   strings: locale.languageCode == "zh" ? MochiStrings.zhHant : MochiStrings.en,
///   ...
/// )
/// ```
@immutable
class MochiStrings {
  const MochiStrings({
    required this.ok,
    required this.cancel,
    required this.back,
    required this.close,
    required this.dismiss,
    required this.remove,
    required this.cut,
    required this.copy,
    required this.paste,
    required this.selectAll,
  });

  /// Acknowledges an alert, or agrees to a confirmation.
  final String ok;

  /// Backs out of a question without answering it.
  final String cancel;

  /// A header's back action.
  final String back;

  /// Closes a page, a toast, a panel.
  final String close;

  /// The screen reader's name for the barrier behind a modal, which dismisses it when tapped.
  final String dismiss;

  /// Takes one item out of a set, such as the × on a badge.
  final String remove;

  /// A text field's context menu.
  final String cut;
  final String copy;
  final String paste;
  final String selectAll;

  static const en = MochiStrings(
    ok: "OK",
    cancel: "Cancel",
    back: "Back",
    close: "Close",
    dismiss: "Dismiss",
    remove: "Remove",
    cut: "Cut",
    copy: "Copy",
    paste: "Paste",
    selectAll: "Select all",
  );

  static const zhHant = MochiStrings(
    ok: "確定",
    cancel: "取消",
    back: "返回",
    close: "關閉",
    dismiss: "關閉",
    remove: "移除",
    cut: "剪下",
    copy: "複製",
    paste: "貼上",
    selectAll: "全選",
  );

  static const standard = en;

  MochiStrings copyWith({
    String? ok,
    String? cancel,
    String? back,
    String? close,
    String? dismiss,
    String? remove,
    String? cut,
    String? copy,
    String? paste,
    String? selectAll,
  }) => MochiStrings(
    ok: ok ?? this.ok,
    cancel: cancel ?? this.cancel,
    back: back ?? this.back,
    close: close ?? this.close,
    dismiss: dismiss ?? this.dismiss,
    remove: remove ?? this.remove,
    cut: cut ?? this.cut,
    copy: copy ?? this.copy,
    paste: paste ?? this.paste,
    selectAll: selectAll ?? this.selectAll,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MochiStrings &&
          ok == other.ok &&
          cancel == other.cancel &&
          back == other.back &&
          close == other.close &&
          dismiss == other.dismiss &&
          remove == other.remove &&
          cut == other.cut &&
          copy == other.copy &&
          paste == other.paste &&
          selectAll == other.selectAll;

  @override
  int get hashCode => Object.hash(ok, cancel, back, close, dismiss, remove, cut, copy, paste, selectAll);
}
