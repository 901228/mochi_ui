import "package:flutter/rendering.dart";
import "package:flutter/scheduler.dart";
import "package:flutter/widgets.dart";

import "mochi_ui.dart";

part "gallery/buttons.dart";
part "gallery/common.dart";
part "gallery/content.dart";
part "gallery/dates.dart";
part "gallery/foundations.dart";
part "gallery/inputs.dart";
part "gallery/navigation.dart";
part "gallery/overlays.dart";

void main() => runApp(const PreviewApp());

class PreviewApp extends StatefulWidget {
  const PreviewApp({super.key});

  @override
  State<PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<PreviewApp> {
  MochiThemeMode _mode = MochiThemeMode.system;
  bool _touch = MochiTheme.defaultTouch;
  bool _zh = false;
  var _look = const _Look();

  @override
  Widget build(BuildContext context) {
    final brand = _look.brand;
    final defaults = MochiDefaults(layering: _look.layering);

    return MochiApp(
      title: "Mochi UI Preview",
      themeMode: _mode,
      touch: _touch,
      strings: _zh ? MochiStrings.zhHant : MochiStrings.en,
      radius: _look.radius.value,
      density: _look.density,
      textScale: _look.textScale,
      lightTheme: MochiTheme.light.copyWith(
        defaults: defaults,
        colors: brand == null ? null : MochiColors.branded(primary: brand),
      ),
      darkTheme: MochiTheme.dark.copyWith(
        defaults: defaults,
        colors: brand == null ? null : MochiColors.branded(brightness: Brightness.dark, primary: brand),
      ),
      home: _Gallery(
        look: _look,
        onLookChanged: (look) => setState(() => _look = look),
        mode: _mode,
        onModeChanged: (mode) => setState(() => _mode = mode),
        touch: _touch,
        onTouchChanged: (touch) => setState(() => _touch = touch),
        zh: _zh,
        onZhChanged: (zh) => setState(() => _zh = zh),
      ),
    );
  }
}

/// One page of the gallery: what the sidebar lists, and what the body shows.
@immutable
class _Page {
  const _Page({required this.name, required this.icon, required this.knobs, required this.sections});

  final String name;
  final IconData icon;

  /// Which knobs the bar at the top of this page offers; the samples that care read them from
  /// [_Knobs].
  final Set<_Knob> knobs;

  final List<(String, Widget)> sections;
}

/// What a page can hand its samples. A page only offers the ones its samples read, so a knob
/// that changes nothing is never on screen.
enum _Knob { size, intent, enabled }

/// The knobs the page is set to, read by the samples that answer to them.
class _Knobs extends InheritedWidget {
  const _Knobs({required this.size, required this.intent, required this.enabled, required super.child});

  final MochiSize size;
  final MochiIntent intent;
  final bool enabled;

  static _Knobs of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Knobs>() ??
      const _Knobs(size: MochiSize.md, intent: MochiIntent.primary, enabled: true, child: SizedBox());

  @override
  bool updateShouldNotify(_Knobs old) => size != old.size || intent != old.intent || enabled != old.enabled;
}

/// The width the page is shown at, so the breakpoint rules can be seen without resizing the
/// window: it sets [ResponsiveScope] as well as the box, since a sheet-or-popover decision is
/// made from the tier rather than from the pixels.
enum _Viewport {
  mobile("mobile", 420, MochiScreenSize.mobile),
  tablet("tablet", 900, MochiScreenSize.tablet),
  full("full", double.infinity, null);

  const _Viewport(this.label, this.width, this.screen);

  final String label;
  final double width;
  final MochiScreenSize? screen;
}

class _Gallery extends StatefulWidget {
  const _Gallery({
    required this.mode,
    required this.onModeChanged,
    required this.touch,
    required this.onTouchChanged,
    required this.zh,
    required this.onZhChanged,
    required this.look,
    required this.onLookChanged,
  });

  final _Look look;
  final ValueChanged<_Look> onLookChanged;

  final MochiThemeMode mode;
  final ValueChanged<MochiThemeMode> onModeChanged;

  final bool touch;
  final ValueChanged<bool> onTouchChanged;

  final bool zh;
  final ValueChanged<bool> onZhChanged;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _page = 0;
  bool _railed = false;
  var _viewport = _Viewport.full;

  MochiSize _size = MochiSize.md;
  MochiIntent _intent = MochiIntent.primary;
  bool _enabled = true;

  /// A fresh controller per page, so a page opens at its top rather than where the last one was
  /// scrolled to.
  final _scrollKey = GlobalKey();

  List<_Page> get _pages => [
    _Page(
      name: "foundations",
      icon: TablerIcons.palette,
      knobs: const {},
      sections: const [
        ("typography", _TypographySample()),
        ("geometry", _GeometrySample()),
        ("components", _ComponentsSample()),
      ],
    ),
    _Page(
      name: "buttons",
      icon: TablerIcons.squareRoundedChevronRight,
      knobs: const {_Knob.size, _Knob.intent, _Knob.enabled},
      sections: [
        ("knobs", const _ButtonKnobs()),
        ("sizes", const _SizeSample()),
        ("waiting", const _WaitingSample()),
        ("playground", const _Playground()),
        for (final appearance in MochiButtonAppearance.values)
          ("button · ${appearance.name}", _Wide(child: _AppearanceTable(appearance: appearance))),
      ],
    ),
    _Page(
      name: "inputs",
      icon: TablerIcons.forms,
      knobs: const {_Knob.size, _Knob.intent, _Knob.enabled},
      sections: const [
        ("knobs", _InputKnobs()),
        ("text field", _TextFieldSample()),
        ("checkbox", _CheckboxSample()),
        ("radio", _RadioSample()),
        ("stepper", _StepperSample()),
        ("select", _SelectSample()),
        ("autocomplete", _AutocompleteSample()),
        ("otp field", _OtpSample()),
        ("search bar", _SearchSample()),
        ("slider", _SliderSample()),
        ("segmented control", _SegmentedSample()),
        ("colour picker", _ColorPickerSample()),
      ],
    ),
    _Page(
      name: "navigation",
      icon: TablerIcons.map2,
      knobs: const {},
      sections: const [
        ("sidebar", _SidebarSample()),
        ("bottom nav", _BottomNavSample()),
        ("breadcrumb + pagination", _TrailSample()),
        ("menubar", _MenubarSample()),
        ("tree", _TreeSample()),
        ("scaffold + header", _ScaffoldSample()),
      ],
    ),
    _Page(
      name: "content",
      icon: TablerIcons.layoutList,
      knobs: const {},
      sections: const [
        ("tiles", _TileSample()),
        ("swipe actions", _SwipeSample()),
        ("accordion", _AccordionSample()),
        ("collapsible", _CollapsibleSample()),
        ("reveal", _RevealSample()),
        ("avatar", _AvatarSample()),
        ("skeleton", _SkeletonSample()),
        ("sortable", _SortableSample()),
        ("resizable", _ResizableSample()),
        ("refresh", _RefreshSample()),
        ("scroll area", _ScrollAreaSample()),
      ],
    ),
    _Page(
      name: "dates",
      icon: TablerIcons.calendarMonth,
      knobs: const {_Knob.size, _Knob.intent, _Knob.enabled},
      sections: const [
        ("knobs", _DateKnobs()),
        ("calendar", _CalendarSample()),
        ("date picker", _DatePickerSample()),
        ("time picker", _TimePickerSample()),
        ("date and time picker", _DateTimePickerSample()),
      ],
    ),
    _Page(
      name: "overlays",
      icon: TablerIcons.layersIntersect,
      knobs: const {},
      sections: const [
        ("transitions", _TransitionSample()),
        ("popover", _PopoverSample()),
        ("menu", _MenuSample()),
        ("dialog", _DialogSample()),
        ("sheet", _SheetSample()),
        ("toast", _ToastSample()),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;
    final pages = _pages;
    final page = pages[_page];

    final body = MochiScaffold(
      padding: EdgeInsets.zero,
      header: _TopBar(
        page: page,
        viewport: _viewport,
        onViewportChanged: (viewport) => setState(() => _viewport = viewport),
        look: widget.look,
        onLookChanged: widget.onLookChanged,
        mode: widget.mode,
        onModeChanged: widget.onModeChanged,
        touch: widget.touch,
        onTouchChanged: widget.onTouchChanged,
        zh: widget.zh,
        onZhChanged: widget.onZhChanged,
        size: _size,
        onSizeChanged: (size) => setState(() => _size = size),
        intent: _intent,
        onIntentChanged: (intent) => setState(() => _intent = intent),
        enabled: _enabled,
        onEnabledChanged: (enabled) => setState(() => _enabled = enabled),
      ),
      child: _Viewporter(
        viewport: _viewport,
        child: _Knobs(
          size: _size,
          intent: _intent,
          enabled: _enabled,
          child: SingleChildScrollView(
            // Keyed by the page, so opening one starts at its top instead of halfway down where
            // the last one was left.
            key: ValueKey(_page),
            padding: EdgeInsets.all(g.space.xl),
            child: Column(
              key: _scrollKey,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (title, sample) in page.sections) ...[
                  _ThemedText(title, .section),
                  SizedBox(height: g.space.sm),
                  sample,
                  SizedBox(height: g.space.xl),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return Row(
      children: [
        MochiSidebar(
          collapsed: _railed,
          header: MochiSidebarHeading(
            const Text("Mochi UI"),
            trailing: MochiButton.icon(
              size: MochiSize.sm,
              intent: MochiIntent.neutral,
              appearance: MochiButtonAppearance.ghost,
              tooltip: _railed ? "Expand" : "Collapse",
              onPress: () => setState(() => _railed = !_railed),
              icon: Icon(
                _railed ? TablerIcons.layoutSidebarRightCollapse : TablerIcons.layoutSidebarLeftCollapse,
              ),
            ),
          ),
          footer: MochiSidebarItem(
            icon: const Icon(TablerIcons.ruler),
            label: const Text("sizing"),
            tooltip: "Watch sizes ease between the two scales",
            onPress: () => Navigator.of(context).push(
              MochiPageRoute<void>(
                builder: (_) =>
                    _SizingPage(onTouchChanged: widget.onTouchChanged, onModeChanged: widget.onModeChanged),
              ),
            ),
          ),
          children: [
            for (final (index, entry) in pages.indexed)
              MochiSidebarItem(
                icon: Icon(entry.icon),
                label: Text(entry.name),
                selected: index == _page,
                onPress: () => setState(() => _page = index),
              ),
          ],
        ),
        Expanded(child: body),
      ],
    );
  }
}

/// The page at the width it is being previewed at, and under the matching breakpoint.
class _Viewporter extends StatelessWidget {
  const _Viewporter({required this.viewport, required this.child});

  final _Viewport viewport;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (viewport.screen == null) return child;

    final colors = context.colors;

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: viewport.width,
        decoration: BoxDecoration(
          border: Border.symmetric(vertical: BorderSide(color: colors.border)),
        ),
        // The tier as well as the box: a picker asks the breakpoint whether it is a popover or a
        // sheet, not the pixels it happens to have.
        child: ResponsiveScope(size: viewport.screen!, child: child),
      ),
    );
  }
}

/// Everything above the page: what it is, how wide to show it, and the knobs it answers to.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.page,
    required this.viewport,
    required this.onViewportChanged,
    required this.look,
    required this.onLookChanged,
    required this.mode,
    required this.onModeChanged,
    required this.touch,
    required this.onTouchChanged,
    required this.zh,
    required this.onZhChanged,
    required this.size,
    required this.onSizeChanged,
    required this.intent,
    required this.onIntentChanged,
    required this.enabled,
    required this.onEnabledChanged,
  });

  final _Page page;

  final _Viewport viewport;
  final ValueChanged<_Viewport> onViewportChanged;

  final _Look look;
  final ValueChanged<_Look> onLookChanged;

  final MochiThemeMode mode;
  final ValueChanged<MochiThemeMode> onModeChanged;

  final bool touch;
  final ValueChanged<bool> onTouchChanged;

  final bool zh;
  final ValueChanged<bool> onZhChanged;

  final MochiSize size;
  final ValueChanged<MochiSize> onSizeChanged;

  final MochiIntent intent;
  final ValueChanged<MochiIntent> onIntentChanged;

  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;

    Widget choice(String label, bool selected, VoidCallback onPress) => MochiButton(
      intent: MochiIntent.neutral,
      appearance: MochiButtonAppearance.ghost,
      size: MochiSize.xs,
      selected: selected,
      onPress: onPress,
      child: Text(label),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.surface,
        border: Border(bottom: BorderSide(color: theme.colors.border)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: g.space.lg, vertical: g.space.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: g.space.xs,
          children: [
            Row(
              children: [
                _ThemedText(page.name, .title),
                const Spacer(),
                for (final option in _Viewport.values)
                  Padding(
                    padding: EdgeInsets.only(left: g.space.xs2),
                    child: choice(option.label, viewport == option, () => onViewportChanged(option)),
                  ),
                SizedBox(width: g.space.md),
                MochiButton(
                  intent: MochiIntent.neutral,
                  appearance: MochiButtonAppearance.ghost,
                  size: MochiSize.xs,
                  selected: touch,
                  tooltip: "Touch-first sizing",
                  onPress: () => onTouchChanged(!touch),
                  prefix: const Icon(TablerIcons.handFinger),
                  child: const Text("touch"),
                ),
                SizedBox(width: g.space.xs2),
                MochiButton(
                  intent: MochiIntent.neutral,
                  appearance: MochiButtonAppearance.ghost,
                  size: MochiSize.xs,
                  selected: zh,
                  tooltip: "MochiStrings.zhHant: the words components say themselves",
                  onPress: () => onZhChanged(!zh),
                  prefix: const Icon(TablerIcons.language),
                  child: const Text("中文"),
                ),
                SizedBox(width: g.space.xs2),
                for (final m in MochiThemeMode.values)
                  Padding(
                    padding: EdgeInsets.only(left: g.space.xs2),
                    child: MochiButton.icon(
                      intent: MochiIntent.neutral,
                      appearance: MochiButtonAppearance.ghost,
                      size: MochiSize.xs,
                      selected: m == mode,
                      tooltip: switch (m) {
                        .system => "Follow the system theme",
                        .light => "Always light",
                        .dark => "Always dark",
                      },
                      onPress: () => onModeChanged(m),
                      icon: Icon(switch (m) {
                        .system => TablerIcons.deviceDesktop,
                        .light => TablerIcons.sun,
                        .dark => TablerIcons.moon,
                      }),
                    ),
                  ),
              ],
            ),
            _LookBar(look: look, onChanged: onLookChanged),
            if (page.knobs.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (page.knobs.contains(_Knob.size)) ...[
                    const _ThemedText("size", .muted),
                    for (final value in MochiSize.values)
                      choice(value.name, size == value, () => onSizeChanged(value)),
                    SizedBox(width: g.space.md),
                  ],
                  if (page.knobs.contains(_Knob.intent)) ...[
                    const _ThemedText("intent", .muted),
                    for (final value in MochiIntent.values)
                      choice(value.name, intent == value, () => onIntentChanged(value)),
                    SizedBox(width: g.space.md),
                  ],
                  if (page.knobs.contains(_Knob.enabled))
                    choice("enabled", enabled, () => onEnabledChanged(!enabled)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
