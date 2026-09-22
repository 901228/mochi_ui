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
    required this.search,
    required this.clear,
    required this.previousMonth,
    required this.nextMonth,
    required this.months,
    required this.weekdays,
    this.monthYear = _monthThenYear,
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

  /// A search field's own hint, when it is given none.
  final String search;

  /// Lets go of everything that was picked: a calendar gathering days, a filter.
  final String clear;

  /// A calendar's two arrows.
  final String previousMonth;
  final String nextMonth;

  /// The twelve month names, January first.
  final List<String> months;

  /// The seven weekday names as a calendar's header writes them — short — Monday first, the
  /// order [DateTime.monday] counts in.
  final List<String> weekdays;

  /// How a calendar says which month it is showing. English puts the year after the month; other
  /// languages don't.
  final String Function(String month, int year) monthYear;

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
    search: "Search",
    clear: "Clear",
    previousMonth: "Previous month",
    nextMonth: "Next month",
    months: [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ],
    weekdays: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
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
    search: "搜尋",
    clear: "清除",
    previousMonth: "上個月",
    nextMonth: "下個月",
    months: ["1 月", "2 月", "3 月", "4 月", "5 月", "6 月", "7 月", "8 月", "9 月", "10 月", "11 月", "12 月"],
    weekdays: ["一", "二", "三", "四", "五", "六", "日"],
    monthYear: _yearThenMonth,
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
    String? search,
    String? clear,
    String? previousMonth,
    String? nextMonth,
    List<String>? months,
    List<String>? weekdays,
    String Function(String month, int year)? monthYear,
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
    search: search ?? this.search,
    clear: clear ?? this.clear,
    previousMonth: previousMonth ?? this.previousMonth,
    nextMonth: nextMonth ?? this.nextMonth,
    months: months ?? this.months,
    weekdays: weekdays ?? this.weekdays,
    monthYear: monthYear ?? this.monthYear,
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
          search == other.search &&
          clear == other.clear &&
          previousMonth == other.previousMonth &&
          nextMonth == other.nextMonth &&
          _sameWords(months, other.months) &&
          _sameWords(weekdays, other.weekdays) &&
          monthYear == other.monthYear &&
          cut == other.cut &&
          copy == other.copy &&
          paste == other.paste &&
          selectAll == other.selectAll;

  @override
  int get hashCode => Object.hash(
    ok,
    cancel,
    back,
    close,
    dismiss,
    remove,
    search,
    clear,
    previousMonth,
    nextMonth,
    Object.hashAll(months),
    Object.hashAll(weekdays),
    monthYear,
    cut,
    copy,
    paste,
    selectAll,
  );
}

/// English and most of Europe: the month, then the year.
String _monthThenYear(String month, int year) => "$month $year";

/// Chinese, Japanese, Korean: the year first, and the month written as a number with a word
/// after it, which is already how [MochiStrings.months] reads there.
String _yearThenMonth(String month, int year) => "$year 年 $month";

bool _sameWords(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }

  return true;
}
