import "package:flutter/scheduler.dart";
import "package:flutter/widgets.dart";

import "../theme/theme.dart";
import "scaffold.dart";

/// A page's title written large at the top of its content, which hands over to the header's own
/// title as it scrolls away — a phone's settings screens, a list of records.
///
/// It is part of the content, not of the header: put it first in the page's scroll view and it
/// scrolls up with the rows, under the header, where the header's [MochiHeader.title] fades in once
/// it has nearly gone. So the header keeps one height throughout, and the list keeps its padding;
/// nothing is collapsed, only covered.
///
/// ```dart
/// MochiScaffold(
///   extendBody: true,
///   header: MochiHeader(title: const Text("Records"), alignment: .center),
///   child: ListView(children: [const MochiLargeTitle(Text("Records")), ...rows]),
/// )
/// ```
///
/// Outside a [MochiScaffold] it is only a large heading.
class MochiLargeTitle extends StatefulWidget {
  const MochiLargeTitle(this.child, {super.key, this.padding});

  final Widget child;

  /// Around the title. Defaults to a little room below it, and none elsewhere: the scroll view's
  /// own padding lines it up with the rows under it.
  final EdgeInsetsGeometry? padding;

  @override
  State<MochiLargeTitle> createState() => _MochiLargeTitleState();
}

class _MochiLargeTitleState extends State<MochiLargeTitle> {
  MochiScaffoldState? _scaffold;
  ScrollPosition? _scroll;
  bool _scheduled = false;

  /// Where this was when last laid out, and how far the list had scrolled then. A scroll is heard
  /// before the frame lays the list out again, so measuring the box there would read where it
  /// *was*; the scroll's own distance says where it is.
  double? _top;
  double _pixels = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scaffold = MochiScaffold.maybeOf(context);
    if (scaffold != _scaffold) {
      _release(_scaffold);
      _scaffold = scaffold;
    }
    final scroll = Scrollable.maybeOf(context)?.position;
    if (scroll != _scroll) {
      _scroll?.removeListener(_scrolled);
      _scroll = scroll?..addListener(_scrolled);
    }
    _measureAfterLayout();
  }

  @override
  void dispose() {
    _scroll?.removeListener(_scrolled);
    // The page no longer has one: the header's title is its own again.
    _release(_scaffold);
    super.dispose();
  }

  /// After the frame, not now: this runs while the tree is being built or torn down, where the
  /// header must not be told to rebuild. And only if no other large title has spoken since.
  void _release(MochiScaffoldState? scaffold) {
    if (scaffold == null) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (scaffold.mounted && scaffold.largeTitleOwner == this) {
        scaffold.largeTitleOwner = null;
        scaffold.largeTitleCovered.value = null;
      }
    });
  }

  void _scrolled() {
    final top = _top;
    final scroll = _scroll;
    if (top == null || scroll == null || scroll.axis != Axis.vertical) return _measureAfterLayout();
    final moved = scroll.pixels - _pixels;
    _report(axisDirectionIsReversed(scroll.axisDirection) ? top + moved : top - moved);
    _measureAfterLayout();
  }

  void _measureAfterLayout() {
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) _measure();
    });
  }

  /// Where this is now that it has been laid out.
  void _measure() {
    final box = context.findRenderObject() as RenderBox?;
    if (_scaffold == null || box == null || !box.hasSize || !box.attached) return;
    _top = box.localToGlobal(Offset.zero).dy;
    _pixels = _scroll?.pixels ?? 0;
    _report(_top!);
  }

  /// How much of this has gone under the header's bottom edge, with its top at [top].
  void _report(double top) {
    final scaffold = _scaffold;
    final box = context.findRenderObject() as RenderBox?;
    if (scaffold == null || box == null || !box.hasSize) return;
    final height = box.size.height;
    scaffold.largeTitleOwner = this;
    scaffold.largeTitleCovered.value = height == 0
        ? 1
        : ((scaffold.headerBottom - top) / height).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    // Measured again once laid out: a rebuild can move it without a scroll.
    _measureAfterLayout();

    return Padding(
      padding: widget.padding ?? EdgeInsets.only(bottom: theme.geometry.space.sm),
      child: Semantics(
        header: true,
        child: DefaultTextStyle(
          style: theme.typography.title.xl3.copyWith(color: theme.colors.foreground),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          child: widget.child,
        ),
      ),
    );
  }
}
