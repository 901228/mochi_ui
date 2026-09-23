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
    required this.reorder,
    required this.goToPage,
    required this.search,
    required this.clear,
    required this.pickDate,
    required this.pickTime,
    required this.am,
    required this.pm,
    this.date = _dayMonthYear,
    this.dateRange = _enRange,
    required this.previousMonth,
    required this.nextMonth,
    required this.previousPage,
    required this.nextPage,
    required this.pagination,
    this.pageNumber = _pageNumber,
    required this.expand,
    required this.collapse,
    required this.months,
    required this.monthsShort,
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

  /// The grip a sortable row is dragged by, which has no words of its own.
  final String reorder;

  /// What a pagination's … asks for when it is pressed.
  final String goToPage;

  /// A search field's own hint, when it is given none.
  final String search;

  /// Lets go of everything that was picked: a calendar gathering days, a filter.
  final String clear;

  /// What a date field says while it is empty.
  final String pickDate;

  /// What a time field says while it is empty.
  final String pickTime;

  /// The two halves of a twelve-hour clock.
  final String am;
  final String pm;

  /// How a day is written out in a field. English counts up, Chinese counts down.
  final String Function(int day, String month, int year) date;

  /// How a run of days is written out, with whatever the two ends share written once: a field
  /// showing "12 July 2026 – 18 July 2026" says the same thing twice and then runs out of room.
  final String Function(DateTime start, DateTime end, List<String> months) dateRange;

  /// A calendar's two arrows.
  final String previousMonth;
  final String nextMonth;

  /// A pagination's arrows, and the name of the row itself.
  final String previousPage;
  final String nextPage;
  final String pagination;

  /// How a page's button names itself to a screen reader, current or not.
  final String Function(int page, bool current) pageNumber;

  /// What opens and closes a branch of a tree, or anything else that folds.
  final String expand;
  final String collapse;

  /// The twelve month names, January first.
  final List<String> months;

  /// The same twelve, short enough for a range to write two of them and still fit a field. In a
  /// language whose months are already short — a number and a word — these are the same list.
  final List<String> monthsShort;

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
    reorder: "Reorder",
    goToPage: "Go to page",
    search: "Search",
    clear: "Clear",
    pickDate: "Pick a date",
    pickTime: "Pick a time",
    am: "AM",
    pm: "PM",
    previousMonth: "Previous month",
    nextMonth: "Next month",
    previousPage: "Previous page",
    nextPage: "Next page",
    pagination: "Pagination",
    expand: "Expand",
    collapse: "Collapse",
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
    monthsShort: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
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
    reorder: "重新排序",
    goToPage: "跳至頁數",
    search: "搜尋",
    clear: "清除",
    pickDate: "選擇日期",
    pickTime: "選擇時間",
    am: "上午",
    pm: "下午",
    previousMonth: "上個月",
    nextMonth: "下個月",
    previousPage: "上一頁",
    nextPage: "下一頁",
    pagination: "分頁",
    pageNumber: _zhPageNumber,
    expand: "展開",
    collapse: "收合",
    months: ["1 月", "2 月", "3 月", "4 月", "5 月", "6 月", "7 月", "8 月", "9 月", "10 月", "11 月", "12 月"],
    monthsShort: ["1 月", "2 月", "3 月", "4 月", "5 月", "6 月", "7 月", "8 月", "9 月", "10 月", "11 月", "12 月"],
    weekdays: ["一", "二", "三", "四", "五", "六", "日"],
    monthYear: _yearThenMonth,
    date: _yearMonthDay,
    dateRange: _zhRange,
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
    String? reorder,
    String? goToPage,
    String? search,
    String? clear,
    String? pickDate,
    String? pickTime,
    String? am,
    String? pm,
    String Function(int day, String month, int year)? date,
    String Function(DateTime start, DateTime end, List<String> months)? dateRange,
    String? previousMonth,
    String? nextMonth,
    String? previousPage,
    String? nextPage,
    String? pagination,
    String Function(int page, bool current)? pageNumber,
    String? expand,
    String? collapse,
    List<String>? months,
    List<String>? monthsShort,
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
    reorder: reorder ?? this.reorder,
    goToPage: goToPage ?? this.goToPage,
    search: search ?? this.search,
    clear: clear ?? this.clear,
    pickDate: pickDate ?? this.pickDate,
    pickTime: pickTime ?? this.pickTime,
    am: am ?? this.am,
    pm: pm ?? this.pm,
    date: date ?? this.date,
    dateRange: dateRange ?? this.dateRange,
    previousMonth: previousMonth ?? this.previousMonth,
    nextMonth: nextMonth ?? this.nextMonth,
    previousPage: previousPage ?? this.previousPage,
    nextPage: nextPage ?? this.nextPage,
    pagination: pagination ?? this.pagination,
    pageNumber: pageNumber ?? this.pageNumber,
    expand: expand ?? this.expand,
    collapse: collapse ?? this.collapse,
    months: months ?? this.months,
    monthsShort: monthsShort ?? this.monthsShort,
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
          reorder == other.reorder &&
          goToPage == other.goToPage &&
          search == other.search &&
          clear == other.clear &&
          pickDate == other.pickDate &&
          pickTime == other.pickTime &&
          am == other.am &&
          pm == other.pm &&
          date == other.date &&
          dateRange == other.dateRange &&
          previousMonth == other.previousMonth &&
          nextMonth == other.nextMonth &&
          previousPage == other.previousPage &&
          nextPage == other.nextPage &&
          pagination == other.pagination &&
          pageNumber == other.pageNumber &&
          expand == other.expand &&
          collapse == other.collapse &&
          _sameWords(months, other.months) &&
          _sameWords(monthsShort, other.monthsShort) &&
          _sameWords(weekdays, other.weekdays) &&
          monthYear == other.monthYear &&
          cut == other.cut &&
          copy == other.copy &&
          paste == other.paste &&
          selectAll == other.selectAll;

  @override
  // hashAll, not hash: there are more words here than Object.hash takes.
  int get hashCode => Object.hashAll([
    ok,
    cancel,
    back,
    close,
    dismiss,
    remove,
    reorder,
    goToPage,
    search,
    clear,
    pickDate,
    pickTime,
    am,
    pm,
    date,
    dateRange,
    previousMonth,
    nextMonth,
    previousPage,
    nextPage,
    pagination,
    pageNumber,
    expand,
    collapse,
    Object.hashAll(months),
    Object.hashAll(monthsShort),
    Object.hashAll(weekdays),
    monthYear,
    cut,
    copy,
    paste,
    selectAll,
  ]);
}

/// English and most of Europe: the day, the month, the year.
String _dayMonthYear(int day, String month, int year) => "$day $month $year";

/// Chinese, Japanese, Korean: biggest first, and the month is already a number with a word after
/// it in [MochiStrings.months].
String _yearMonthDay(int day, String month, int year) => "$year 年 $month $day 日";

/// English and most of Europe: the month, then the year.
String _monthThenYear(String month, int year) => "$month $year";

/// Chinese, Japanese, Korean: the year first, and the month written as a number with a word
/// after it, which is already how [MochiStrings.months] reads there.
String _yearThenMonth(String month, int year) => "$year 年 $month";

/// "12 – 18 Jul", "12 Jul – 18 Aug", "12 Jul 2026 – 18 Aug 2027": each part is written once, at
/// the first end that needs it, and the year only when it isn't this one.
String _enRange(DateTime start, DateTime end, List<String> months) {
  final from = months[start.month - 1];
  final to = months[end.month - 1];
  final thisYear = start.year == DateTime.now().year && end.year == start.year;

  if (start.year != end.year) {
    return "${start.day} $from ${start.year} – ${end.day} $to ${end.year}";
  }

  final year = thisYear ? "" : " ${end.year}";
  if (start.month != end.month) return "${start.day} $from – ${end.day} $to$year";

  return "${start.day} – ${end.day} $to$year";
}

/// The same rule the other way up: "7 月 12 – 18 日", "7 月 12 日 – 8 月 18 日".
String _zhRange(DateTime start, DateTime end, List<String> months) {
  final from = months[start.month - 1];
  final to = months[end.month - 1];
  final thisYear = start.year == DateTime.now().year && end.year == start.year;

  if (start.year != end.year) {
    return "${start.year} 年 $from ${start.day} 日 – ${end.year} 年 $to ${end.day} 日";
  }

  final year = thisYear ? "" : "${end.year} 年 ";
  if (start.month != end.month) return "$year$from ${start.day} 日 – $to ${end.day} 日";

  return "$year$to ${start.day} – ${end.day} 日";
}

bool _sameWords(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }

  return true;
}

/// English: "Page 4", and the one you are on says so.
String _pageNumber(int page, bool current) => current ? "Page $page, current" : "Page $page";

/// Chinese counts the same way round, with the word after the number.
String _zhPageNumber(int page, bool current) => current ? "第 $page 頁，目前所在" : "第 $page 頁";
