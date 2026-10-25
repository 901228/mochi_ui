import "dart:math" as math;

import "package:flutter/gestures.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";

import "../theme/geometry.dart";
import "../theme/responsive.dart";
import "../theme/theme.dart";
import "clip.dart";
import "shape_shadow.dart";
import "fixed_sidebar.dart";

/// A page: an optional header, the content, and an optional footer, on the theme background —
/// and, for an app's home, the navigation around it.
///
/// The content is padded with [MochiGeometry.pagePadding] unless [padding] says otherwise, and
/// fills the space left between header and footer — or, with [extendBody], the whole page, with
/// the bars standing over it.
///
/// ## Navigation
///
/// A [sidebar] stands beside the content from [sidebarFrom] up; below it, a [footer] (a
/// `MochiBottomNav`) takes its place and a [drawer] can be pulled out over the page. Crossing the
/// breakpoint slides one out and the other in, and the page keeps its state across the swap.
///
/// | width                   | sidebar | drawer      | footer |
/// |-------------------------|---------|-------------|--------|
/// | below [sidebarFrom]     | hidden  | can be open | shown  |
/// | [sidebarFrom] and up    | shown   | closed      | hidden |
///
/// Without a [sidebar] nothing is swapped: the footer shows and the drawer opens at every width.
/// What goes in each is the app's, and so is what is chosen in them — the scaffold only decides
/// which of them is showing, so a sidebar and a drawer can hold entirely different things.
///
/// A `MochiHeader` with no prefixes of its own puts a button in front of its title that opens
/// the drawer, whenever there is one to open. Anything else reaches it through
/// [MochiScaffold.of]: `MochiScaffold.of(context).openDrawer()`.
class MochiScaffold extends StatefulWidget {
  const MochiScaffold({
    super.key,
    required this.child,
    this.header,
    this.headerOverlay,
    this.footer,
    this.sidebar,
    this.drawer,
    this.sidebarFrom = MochiScreenSize.tablet,
    this.drawerEdgeDrag = true,
    this.padding,
    this.background,
    this.safeArea = true,
    this.extendBody = false,
    this.immersive = false,
  });

  final Widget child;
  final Widget? header;

  /// Drawn over the [header], from the top of the content's column: as wide as the content, at
  /// least as tall as the header and as tall beyond that as it likes, up to the whole page — a
  /// selection bar that covers the header and whatever sits under it, say.
  ///
  /// It follows the [sidebar] as it slides, narrows to a rail or goes, which nothing outside the
  /// scaffold can do. Only its own box takes presses; the header and the content stay live
  /// everywhere else. Under [extendBody] the header clears the status bar by itself, and so must
  /// this: `MediaQuery.paddingOf(context).top`.
  ///
  /// Given after the page is built, it slides in from the leading edge, over the sidebar, and a
  /// press on it before it has arrived does nothing — it neither reaches the overlay nor the
  /// header under it. Taken away, it slides back out before it goes, letting presses through.
  final Widget? headerOverlay;

  /// Along the bottom: usually a `MochiBottomNav`. Hidden from [sidebarFrom] up when there is a
  /// [sidebar] to take over its job.
  final Widget? footer;

  /// Beside the content from [sidebarFrom] up: usually a `MochiSidebar`.
  final Widget? sidebar;

  /// Pulled out over the page below [sidebarFrom], or at every width when there is no [sidebar].
  final Widget? drawer;

  /// The narrowest screen that has room for the [sidebar].
  final MochiScreenSize sidebarFrom;

  /// Whether a drag from the leading edge pulls the [drawer] out, on a touch screen. Only on a
  /// page with nothing to go back to: on a pushed page that edge drags the page back instead.
  final bool drawerEdgeDrag;

  /// Defaults to [MochiGeometry.pagePadding]; pass [EdgeInsets.zero] for edge-to-edge content.
  ///
  /// Content that scrolls wants zero here and the same padding *inside* the scroll view
  /// (`ListView(padding: context.theme.geometry.pagePadding)`): padded from outside, the view's
  /// edge sits short of the page's, so rows are cut off in mid-air and a raised card's shadow is
  /// clipped at the sides. The scaffold cannot do this by itself, since it cannot tell a list
  /// from a column, which needs the padding outside.
  final EdgeInsetsGeometry? padding;

  /// Defaults to [MochiColors.background].
  final Color? background;

  final bool safeArea;

  /// Whether the content runs under the header and the footer rather than stopping at them, so a
  /// list scrolls on behind the bars.
  ///
  /// The bars are measured as they are laid out — nothing has to declare a height ahead of time,
  /// which a header that grows with the theme's scale could only get wrong — and their heights
  /// are handed to the content as `MediaQuery.padding`. A `ListView` or a `GridView` reads that
  /// on its own and keeps its first and last rows clear of the bars; a `SingleChildScrollView`
  /// does not, so give it `padding: MediaQuery.paddingOf(context)`. The vertical [padding] goes
  /// into the same inset, inside the scroll view, rather than around it, where it would keep the
  /// content from reaching under the bars at all.
  ///
  /// The bars run to the screen's edges and clear the system's insets themselves (a
  /// `MochiHeader` the top one, a `MochiBottomNav` the bottom), so their own fill reaches under
  /// the status bar and the home indicator. A header with nothing behind it — the `plain`
  /// variant — lets the content show through: pair this with `bordered` or `floating`.
  final bool extendBody;

  /// Whether the header, the footer and the sidebar step aside, sliding off their edges, and leave
  /// the whole page to the content — a timer while it runs, say. The content grows into the room
  /// they leave and keeps clear of only the system's insets; the bars stay on the tree, so taking
  /// it back brings them as they were.
  final bool immersive;

  /// The nearest scaffold above [context]. Asserts when there is none — which is the case in the
  /// very `build` that creates the scaffold: put a `Builder` under it.
  static MochiScaffoldState of(BuildContext context) {
    final state = maybeOf(context);
    assert(
      state != null,
      "MochiScaffold.of() was called with a context that has no MochiScaffold above it. The "
      "context of the build that creates a scaffold is above it: wrap the caller in a Builder.",
    );
    return state!;
  }

  static MochiScaffoldState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ScaffoldScope>()?.state;

  @override
  State<MochiScaffold> createState() => MochiScaffoldState();
}

/// What [MochiScaffold.of] hands back: the drawer, and whether there is one to open.
class MochiScaffoldState extends State<MochiScaffold> with TickerProviderStateMixin {
  /// 0 with the footer showing, 1 with the sidebar beside the content.
  late final AnimationController _wide = AnimationController(vsync: this);

  /// 0 shut, 1 all the way out.
  late final AnimationController _drawer = AnimationController(vsync: this);

  /// 0 gone, 1 in place: the header overlay sliding in from the screen's leading edge. Run
  /// linearly; the layout puts the theme's transition curves on it.
  late final AnimationController _overlay = AnimationController(vsync: this);

  /// 0 with the bars in place, 1 with them all gone off the page for [MochiScaffold.immersive].
  late final AnimationController _immersive = AnimationController(vsync: this);

  /// The last header overlay given, kept on the tree while it slides out after being taken away.
  Widget? _overlayChild;

  /// What had the focus before the drawer took it, to be given it back when the drawer shuts.
  FocusNode? _returnFocus;
  final _drawerScope = FocusScopeNode(debugLabel: "MochiScaffold drawer");

  bool _sidebarShown = false;
  bool _initialised = false;

  final _headerKey = GlobalKey(debugLabel: "MochiScaffold header");

  /// How much of the page's `MochiLargeTitle` has gone under the header, 0 to 1, or null when the
  /// page has none. The header fades its own title in from this.
  final largeTitleCovered = ValueNotifier<double?>(null);

  /// The large title that last wrote [largeTitleCovered], so one that leaves clears it only if no
  /// other has taken over since — the next page's, say.
  Object? largeTitleOwner;

  /// The header's bottom edge in global coordinates: where a large title starts to be covered.
  /// The body's top edge when there is no header.
  double get headerBottom {
    final box = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) return box.localToGlobal(Offset(0, box.size.height)).dy;
    final own = context.findRenderObject() as RenderBox?;
    return own == null || !own.hasSize ? 0 : own.localToGlobal(Offset.zero).dy;
  }

  /// Whether [openDrawer] would open something: there is a [MochiScaffold.drawer], and the
  /// screen is not wide enough for the sidebar that takes its place.
  bool get hasDrawer => widget.drawer != null && !_sidebarShown;

  /// Whether the drawer is out, or on its way out.
  bool get isDrawerOpen => _drawer.value > 0 && _drawer.status != AnimationStatus.reverse;

  bool get _animationsOff => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void initState() {
    super.initState();
    // The parts that are hidden come off the tree's paint and focus only once they have finished
    // leaving; that is a rebuild at either end of a run, not on every tick.
    _wide.addStatusListener(_settled);
    _drawer.addStatusListener(_settled);
    _overlay.addStatusListener(_settled);
    _immersive.addStatusListener(_settled);
    _immersive.value = widget.immersive ? 1 : 0;
    // One the page is built with is already there; only one that arrives later slides in.
    _overlayChild = widget.headerOverlay;
    if (_overlayChild != null) _overlay.value = 1;
  }

  @override
  void didUpdateWidget(MochiScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.immersive != oldWidget.immersive) {
      final motion = context.theme.motion;
      if (_animationsOff) {
        _immersive.value = widget.immersive ? 1 : 0;
      } else if (widget.immersive) {
        _immersive.animateTo(1, duration: motion.transitionDuration, curve: motion.transitionCurve);
      } else {
        _immersive.animateBack(
          0,
          duration: motion.transitionReverseDuration,
          curve: motion.transitionReverseCurve,
        );
      }
    }
    final overlay = widget.headerOverlay;
    if (overlay != null) _overlayChild = overlay;
    if ((overlay == null) == (oldWidget.headerOverlay == null)) return;
    if (_animationsOff) {
      _overlay.value = overlay == null ? 0 : 1;
    } else if (overlay == null) {
      _overlay.animateBack(0, duration: context.theme.motion.transitionReverseDuration);
    } else {
      _overlay.animateTo(1, duration: context.theme.motion.transitionDuration);
    }
  }

  void _settled(AnimationStatus status) {
    if (status.isCompleted || status.isDismissed) setState(() {});
  }

  @override
  void dispose() {
    _wide.dispose();
    _drawer.dispose();
    _overlay.dispose();
    _immersive.dispose();
    _drawerScope.dispose();
    largeTitleCovered.dispose();
    super.dispose();
  }

  /// Pulls the drawer out. Does nothing when there is none to open — the screen may have grown
  /// wide enough for the sidebar since the button was drawn.
  void openDrawer() {
    if (!hasDrawer) return;
    _returnFocus ??= FocusManager.instance.primaryFocus;
    setState(() {});
    _run(_drawer, 1);
    _drawerScope.requestFocus();
  }

  void closeDrawer() {
    if (_drawer.value == 0 && !_drawer.isAnimating) return;
    _run(_drawer, 0);
    _restoreFocus();
  }

  void _restoreFocus() {
    final previous = _returnFocus;
    _returnFocus = null;
    if (previous != null && previous.context != null) previous.requestFocus();
  }

  void _run(AnimationController controller, double to) {
    final motion = context.theme.motion;
    if (_animationsOff) {
      controller.value = to;
      return;
    }
    final drawer = identical(controller, _drawer);
    final opening = to > controller.value;
    controller.animateTo(
      to,
      duration: drawer
          ? (opening ? motion.transitionDuration : motion.transitionReverseDuration)
          : motion.sizeDuration,
      curve: drawer ? (opening ? motion.transitionCurve : motion.transitionReverseCurve) : motion.sizeCurve,
    );
  }

  /// Where the sidebar should be at this width, started towards from wherever it is.
  void _syncWidth() {
    final wide = ResponsiveScope.of(context).index >= widget.sidebarFrom.index;
    final shown = widget.sidebar != null && wide;
    if (!_initialised) {
      _initialised = true;
      _sidebarShown = shown;
      _wide.value = shown ? 1 : 0;
      return;
    }
    if (shown == _sidebarShown) return;
    _sidebarShown = shown;
    _run(_wide, shown ? 1 : 0);
    // A drawer standing open as the sidebar comes in would be the same list twice.
    if (shown && _drawer.value > 0) {
      _drawer.value = 0;
      _restoreFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    _syncWidth();
    final theme = context.theme;
    final padding = widget.padding ?? theme.geometry.pagePadding;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final swaps = widget.sidebar != null;
    final immersive = widget.immersive;
    final away = immersive && _immersive.isCompleted;

    // Kept on the tree whichever is showing — a slot that came and went would take the page's
    // state with it — and only taken off paint and focus once it has finished leaving.
    Widget slot(Widget child, {required bool shown, required bool gone}) => ExcludeFocus(
      excluding: !shown,
      child: IgnorePointer(
        ignoring: !shown,
        child: Offstage(offstage: gone, child: child),
      ),
    );

    // What the safe area below puts between the page's edges and the clip around it: a part sliding
    // away has to cross it as well, or it stops in plain sight there and then vanishes.
    final insets = MediaQuery.paddingOf(context);
    final margin = !widget.safeArea || widget.extendBody ? EdgeInsets.zero : insets;

    final page = CustomMultiChildLayout(
      delegate: _ScaffoldLayout(
        wide: _wide,
        overlay: _overlay,
        immersive: _immersive,
        overlayCurve: theme.motion.transitionCurve,
        overlayReverseCurve: theme.motion.transitionReverseCurve,
        rtl: rtl,
        extendBody: widget.extendBody,
        margin: margin,
      ),
      children: [
        LayoutId(
          id: _Slot.body,
          child: widget.extendBody
              ? _ExtendedBody(
                  padding: padding,
                  header: widget.header != null,
                  footer: widget.footer != null,
                  child: widget.child,
                )
              : Padding(padding: padding, child: widget.child),
        ),
        if (widget.header case final header?)
          LayoutId(
            id: _Slot.header,
            child: slot(
              KeyedSubtree(key: _headerKey, child: header),
              shown: !immersive,
              gone: away,
            ),
          ),
        if (widget.footer case final footer?)
          LayoutId(
            id: _Slot.footer,
            child: slot(
              footer,
              shown: !(swaps && _sidebarShown) && !immersive,
              gone: (swaps && _sidebarShown && _wide.value == 1) || away,
            ),
          ),
        if (widget.sidebar case final sidebar?)
          LayoutId(
            id: _Slot.sidebar,
            child: slot(
              sidebar,
              shown: _sidebarShown && !immersive,
              gone: (!_sidebarShown && _wide.value == 0) || away,
            ),
          ),
        if (_overlayChild case final overlay? when !_overlay.isDismissed)
          LayoutId(
            id: _Slot.headerOverlay,
            // Slid by the layout, over the sidebar; one on its way out takes nothing, and presses
            // on one arriving go nowhere: not to it, half in place, nor to what it is covering.
            child: ExcludeFocus(
              excluding: widget.headerOverlay == null,
              child: IgnorePointer(
                ignoring: widget.headerOverlay == null,
                child: AbsorbPointer(
                  absorbing: widget.headerOverlay != null && !_overlay.isCompleted,
                  child: overlay,
                ),
              ),
            ),
          ),
      ],
    );

    // With the body under the bars, none at all: every part clears the insets inside its own fill,
    // so the header's and the sidebar's grounds reach the screen's edges, past a notch on its side.
    final framed = !widget.safeArea || widget.extendBody ? page : SafeArea(child: page);

    final canEdgeDrag =
        hasDrawer &&
        widget.drawerEdgeDrag &&
        // A pushed page's leading edge drags it back; two gestures on one strip would fight.
        !(ModalRoute.of(context)?.canPop ?? false);

    return _ScaffoldScope(
      state: this,
      hasDrawer: hasDrawer,
      child: ColoredBox(
        color: widget.background ?? theme.colors.background,
        // Clipped, so a sidebar sliding in from off the edge is not drawn over its neighbours.
        child: ClipRect(
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              framed,
              if (widget.drawer case final drawer?)
                _DrawerLayer(
                  animation: _drawer,
                  scope: _drawerScope,
                  open: hasDrawer && (_drawer.value > 0 || _drawer.isAnimating),
                  edgeDrag: canEdgeDrag,
                  onClose: closeDrawer,
                  onDragStart: () {
                    _returnFocus ??= FocusManager.instance.primaryFocus;
                    setState(() {});
                  },
                  onDragEnd: (open) {
                    _run(_drawer, open ? 1 : 0);
                    if (open) {
                      _drawerScope.requestFocus();
                    } else {
                      _restoreFocus();
                    }
                  },
                  child: drawer,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScaffoldScope extends InheritedWidget {
  const _ScaffoldScope({required this.state, required this.hasDrawer, required super.child});

  final MochiScaffoldState state;

  /// Carried so a header's drawer button comes and goes as the width crosses the breakpoint.
  final bool hasDrawer;

  @override
  bool updateShouldNotify(_ScaffoldScope old) => old.state != state || old.hasDrawer != hasDrawer;
}

enum _Slot { body, header, footer, sidebar, headerOverlay }

/// Constraints that also say how tall the bars standing over the body came out.
///
/// That is how the measurement gets from layout to the body's build without a frame's delay: the
/// body is a `LayoutBuilder`, which builds during layout with whatever constraints it is handed.
class _BodyConstraints extends BoxConstraints {
  _BodyConstraints.tight(
    super.size, {
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
  }) : super.tight();

  final double top;
  final double bottom;

  /// How far the body stands in from the page's left and right edges: a sidebar's width, which
  /// already keeps it clear of the system's inset on that side.
  final double left;
  final double right;

  @override
  bool operator ==(Object other) =>
      other is _BodyConstraints &&
      super == other &&
      top == other.top &&
      bottom == other.bottom &&
      left == other.left &&
      right == other.right;

  @override
  int get hashCode => Object.hash(super.hashCode, top, bottom, left, right);
}

/// Lays out the page around a sidebar that slides in from the leading edge and a footer that
/// slides down out of sight, both by [wide]: laid out again on every tick of it, never rebuilt.
class _ScaffoldLayout extends MultiChildLayoutDelegate {
  _ScaffoldLayout({
    required this.wide,
    required this.overlay,
    required this.immersive,
    required this.overlayCurve,
    required this.overlayReverseCurve,
    required this.rtl,
    required this.extendBody,
    required this.margin,
  }) : super(relayout: Listenable.merge([wide, overlay, immersive]));

  final Animation<double> wide;

  /// The bars, 0 in place and 1 gone off their edges.
  final Animation<double> immersive;

  /// The header overlay, 0 off the screen's leading edge and 1 in place.
  final Animation<double> overlay;
  final Curve overlayCurve;
  final Curve overlayReverseCurve;
  final bool rtl;
  final bool extendBody;

  /// How far outside the page the clip is on each side, for a part sliding off it to go past.
  final EdgeInsets margin;

  @override
  void performLayout(Size size) {
    final t = wide.value;
    final shown = 1 - immersive.value;

    // The sidebar as tall as the page and as wide as it likes; the room it takes grows with t.
    var beside = 0.0;
    if (hasChild(_Slot.sidebar)) {
      final width = layoutChild(_Slot.sidebar, BoxConstraints.tightFor(height: size.height)).width;
      final shownPart = t * shown;
      beside = width * shownPart;
      final away = 1 - shownPart;
      positionChild(
        _Slot.sidebar,
        Offset(rtl ? size.width - width + (width + margin.right) * away : -(width + margin.left) * away, 0),
      );
    }
    final left = rtl ? 0.0 : beside;
    final width = math.max(0.0, size.width - beside);

    // The bars as wide as what is left, and with no bound on their height, as a column would
    // give them: a header centres its title with an `Align`, which fills a bounded height and
    // turned the bar into the whole page.
    final bar = BoxConstraints.tightFor(width: width);

    var top = 0.0;
    if (hasChild(_Slot.header)) {
      final height = layoutChild(_Slot.header, bar).height;
      top = height * shown;
      positionChild(_Slot.header, Offset(left, -(height + margin.top) * (1 - shown)));
    }
    var bottom = 0.0;
    if (hasChild(_Slot.footer)) {
      final height = layoutChild(_Slot.footer, bar).height;
      // Down and out of sight as the sidebar comes in; only what still shows is kept clear.
      final shownPart = (1 - t) * shown;
      bottom = height * shownPart;
      positionChild(_Slot.footer, Offset(left, size.height - bottom + margin.bottom * (1 - shownPart)));
    }
    if (hasChild(_Slot.headerOverlay)) {
      layoutChild(
        _Slot.headerOverlay,
        BoxConstraints(
          minWidth: width,
          maxWidth: width,
          minHeight: math.min(top, size.height),
          maxHeight: size.height,
        ),
      );
      // All the way off the screen, not just its own width: that only gets it to the sidebar's
      // edge, where it would be seen to stop and vanish, since it is drawn over the sidebar.
      final curve = overlay.status == AnimationStatus.reverse ? overlayReverseCurve : overlayCurve;
      final away = 1 - curve.transform(overlay.value);
      final travel = rtl ? size.width - left : left + width;
      positionChild(_Slot.headerOverlay, Offset(left + (rtl ? travel : -travel) * away, 0));
    }

    if (extendBody) {
      layoutChild(
        _Slot.body,
        _BodyConstraints.tight(
          Size(width, size.height),
          top: top,
          bottom: bottom,
          left: left,
          right: size.width - left - width,
        ),
      );
      positionChild(_Slot.body, Offset(left, 0));
    } else {
      layoutChild(_Slot.body, BoxConstraints.tight(Size(width, math.max(0.0, size.height - top - bottom))));
      positionChild(_Slot.body, Offset(left, top));
    }
  }

  @override
  bool shouldRelayout(_ScaffoldLayout oldDelegate) =>
      oldDelegate.wide != wide ||
      oldDelegate.overlay != overlay ||
      oldDelegate.immersive != immersive ||
      oldDelegate.overlayCurve != overlayCurve ||
      oldDelegate.overlayReverseCurve != overlayReverseCurve ||
      oldDelegate.rtl != rtl ||
      oldDelegate.extendBody != extendBody ||
      oldDelegate.margin != margin;
}

class _ExtendedBody extends StatelessWidget {
  const _ExtendedBody({
    required this.padding,
    required this.header,
    required this.footer,
    required this.child,
  });

  final EdgeInsetsGeometry padding;
  final bool header;
  final bool footer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final page = padding.resolve(Directionality.of(context));

    return LayoutBuilder(
      builder: (context, constraints) {
        final bars = constraints as _BodyConstraints;

        // A side with a bar is cleared by the bar's height, which already holds the system's
        // inset; a side without one, or with one sliding away, keeps at least the system's inset.
        // The left and right insets are left to the body too, less what a sidebar takes of them.
        return MediaQuery(
          data: media.copyWith(
            padding: media.padding.copyWith(
              top: (header ? math.max(bars.top, media.padding.top) : media.padding.top) + page.top,
              bottom:
                  (footer ? math.max(bars.bottom, media.padding.bottom) : media.padding.bottom) + page.bottom,
              left: math.max(0.0, media.padding.left - bars.left),
              right: math.max(0.0, media.padding.right - bars.right),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(left: page.left, right: page.right),
            child: child,
          ),
        );
      },
    );
  }
}

/// The drawer over the page: a dimmed page behind it that shuts it when pressed, and the panel
/// coming in from the leading edge. Not a route, so it is rebuilt with the scaffold — a drawer
/// pushed as a route would go on showing what was chosen when it opened.
class _DrawerLayer extends StatefulWidget {
  const _DrawerLayer({
    required this.animation,
    required this.scope,
    required this.open,
    required this.edgeDrag,
    required this.onClose,
    required this.onDragStart,
    required this.onDragEnd,
    required this.child,
  });

  final AnimationController animation;
  final FocusScopeNode scope;

  /// Whether it is out or on its way, so the layer only stands over the page while it is.
  final bool open;
  final bool edgeDrag;
  final VoidCallback onClose;
  final VoidCallback onDragStart;
  final ValueChanged<bool> onDragEnd;
  final Widget child;

  @override
  State<_DrawerLayer> createState() => _DrawerLayerState();
}

class _DrawerLayerState extends State<_DrawerLayer> {
  /// How far in from the edge a drag may start, as a page's back drag does.
  static const _edgeWidth = 20.0;
  static const _flingVelocity = 700.0;

  double _panelWidth = 0;

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  /// Positive when a drag pulls the drawer out: rightwards, or leftwards in right-to-left.
  double get _sign => _rtl ? -1 : 1;

  void _start(DragStartDetails details) {
    widget.animation.stop();
    widget.onDragStart();
  }

  void _update(DragUpdateDetails details) {
    if (_panelWidth == 0) return;
    widget.animation.value += _sign * details.delta.dx / _panelWidth;
  }

  void _end(DragEndDetails details) {
    final velocity = _sign * details.velocity.pixelsPerSecond.dx;
    final open = velocity > _flingVelocity || (velocity > -_flingVelocity && widget.animation.value > 0.5);
    widget.onDragEnd(open);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;
    final colors = theme.colors;
    final media = MediaQuery.of(context);
    final barrier = colors.shadow.withValues(alpha: colors.shadow.a * 0.5);
    final edge = _edgeWidth + (_rtl ? media.systemGestureInsets.right : media.systemGestureInsets.left);

    const touch = {PointerDeviceKind.touch, PointerDeviceKind.stylus, PointerDeviceKind.invertedStylus};

    final strip = PositionedDirectional(
      start: 0,
      top: 0,
      bottom: 0,
      // Past the system's own gesture strip, which would take a drag that starts on the edge.
      width: edge,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        supportedDevices: touch,
        onHorizontalDragStart: widget.edgeDrag ? _start : null,
        onHorizontalDragUpdate: widget.edgeDrag ? _update : null,
        onHorizontalDragEnd: widget.edgeDrag ? _end : null,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final lead = _rtl ? media.padding.right : media.padding.left;
        // As wide as a phone's drawers are: most of the screen, never all of it, so the page
        // that dismisses it is always there to press.
        _panelWidth = math.min(320.0 + lead, constraints.maxWidth * 0.85);

        return AnimatedBuilder(
          animation: widget.animation,
          builder: (context, _) {
            final t = widget.animation.value;
            final shown = widget.open || t > 0;

            return Stack(
              fit: StackFit.passthrough,
              children: [
                // Always there, and under the dimmed page: a drag from the edge makes the drawer
                // showing, and a strip that left the tree then would end the drag it started.
                strip,
                // Same tree open or shut: the layer only stops standing over the page.
                Offstage(
                  offstage: !shown,
                  child: ExcludeFocus(
                    excluding: !shown,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onClose,
                      onHorizontalDragStart: _start,
                      onHorizontalDragUpdate: _update,
                      onHorizontalDragEnd: _end,
                      child: Semantics(
                        label: theme.strings.dismiss,
                        onTap: widget.onClose,
                        child: ColoredBox(
                          color: barrier.withValues(alpha: barrier.a * t),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
                Offstage(
                  offstage: !shown,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionalTranslation(
                      translation: Offset((1 - t) * -_sign, 0),
                      child: SizedBox(
                        width: _panelWidth,
                        child: CallbackShortcuts(
                          bindings: {const SingleActivator(LogicalKeyboardKey.escape): widget.onClose},
                          child: FocusScope(
                            node: widget.scope,
                            child: Semantics(
                              scopesRoute: true,
                              explicitChildNodes: true,
                              child: GestureDetector(
                                onHorizontalDragStart: _start,
                                onHorizontalDragUpdate: _update,
                                onHorizontalDragEnd: _end,
                                child: ShapeShadow(
                                  radius: BorderRadiusDirectional.horizontal(end: g.radius.xl.topLeft),
                                  shadows: g.shadows.of(MochiElevation.lg, colors.shadow),
                                  child: DecoratedBox(
                                    decoration: ShapeDecoration(
                                      color: colors.overlay,
                                      shape: g.shape(
                                        borderRadius: BorderRadiusDirectional.horizontal(
                                          end: g.radius.xl.topLeft,
                                        ).resolve(Directionality.of(context)),
                                      ),
                                    ),
                                    child: MochiClip(
                                      borderRadius: BorderRadiusDirectional.horizontal(
                                        end: g.radius.xl.topLeft,
                                      ).resolve(Directionality.of(context)),
                                      // It runs to the screen's top, bottom and leading edge: the
                                      // insets there are the drawer's own to keep clear, under its
                                      // own fill, as a sidebar or a list does.
                                      child: FixedSidebar(child: widget.child),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
