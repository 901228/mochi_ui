part of "../main.dart";

class _TransitionSample extends StatelessWidget {
  const _TransitionSample();

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Wrap(
      spacing: g.space.sm,
      runSpacing: g.space.sm,
      children: [
        for (final transition in MochiTransition.values)
          MochiButton(
            appearance: MochiButtonAppearance.outlined,
            size: MochiSize.sm,
            onPress: () => Navigator.of(context).push(
              MochiPageRoute<void>(
                transition: transition,
                builder: (context) => MochiScaffold(
                  header: MochiHeader(
                    variant: MochiHeaderVariant.bordered,
                    title: Text("Pushed with ${transition.name}"),
                    prefixes: [MochiAction.back(onPress: () => Navigator.of(context).pop())],
                  ),
                  child: const Center(child: Text("Press back to return")),
                ),
              ),
            ),
            child: Text(transition.name),
          ),
      ],
    );
  }
}

class _PopoverSample extends StatelessWidget {
  const _PopoverSample();

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Wrap(
      spacing: g.space.sm,
      runSpacing: g.space.sm,
      children: [
        for (final side in MochiPopoverSide.values)
          MochiPopover(
            side: side,
            popoverBuilder: (context) => SizedBox(
              width: 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Opens on the ${side.name}"),
                  SizedBox(height: g.space.xs),
                  const Text("Flips when there is no room, and stays inside the window."),
                ],
              ),
            ),
            builder: (context, anchor, _) => MochiButton(
              appearance: MochiButtonAppearance.outlined,
              size: MochiSize.sm,
              focusNode: anchor.focusNode,
              onPress: anchor.toggle,
              child: Text(side.name),
            ),
          ),
        for (final align in MochiPopoverAlign.values)
          MochiPopover(
            align: align,
            popoverBuilder: (context) => SizedBox(width: 220, child: Text("Aligned ${align.name}")),
            builder: (context, anchor, _) => MochiButton(
              appearance: MochiButtonAppearance.soft,
              size: MochiSize.sm,
              focusNode: anchor.focusNode,
              onPress: anchor.toggle,
              child: Text("align ${align.name}"),
            ),
          ),
        // Opened at the pointer rather than against an edge: the shape a context menu takes
        // once MochiContextMenu lands.
        MochiPopover(
          align: MochiPopoverAlign.start,
          // Its anchor only opens, so pressing it again has to be what closes it.
          closeOnAnchorPress: true,
          popoverBuilder: (context) => const SizedBox(width: 160, child: Text("Opened at the pointer")),
          builder: (context, anchor, _) => GestureDetector(
            onSecondaryTapUp: (details) => anchor.open(position: details.localPosition),
            child: MochiCard(
              padding: EdgeInsets.symmetric(horizontal: g.space.sm, vertical: g.space.xs),
              child: const Text("right click me"),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuSample extends StatefulWidget {
  const _MenuSample();

  @override
  State<_MenuSample> createState() => _MenuSampleState();
}

class _MenuSampleState extends State<_MenuSample> {
  String _chosen = "nothing yet";
  String _penalty = "none";
  bool _archived = false;

  List<Widget> _items(BuildContext context) => [
    const MochiMenuLabel(child: Text("Session")),
    MochiMenuItem(
      prefix: const Icon(TablerIcons.pencil),
      title: const Text("Rename"),
      suffix: const Text("F2"),
      onPress: () => setState(() => _chosen = "rename"),
    ),
    MochiMenuItem(
      prefix: Icon(_archived ? TablerIcons.archiveOff : TablerIcons.archive),
      title: Text(_archived ? "Unarchive" : "Archive"),
      onPress: () => setState(() {
        _archived = !_archived;
        _chosen = _archived ? "archive" : "unarchive";
      }),
    ),
    MochiMenuItem(
      prefix: const Icon(TablerIcons.star),
      title: const Text("Selected row"),
      selected: true,
      onPress: () => setState(() => _chosen = "selected row"),
    ),
    const MochiMenuItem(prefix: Icon(TablerIcons.ban), title: Text("Disabled row")),
    MochiSubmenu(
      prefix: const Icon(TablerIcons.gavel),
      title: const Text("Penalty"),
      menuBuilder: (context) => [
        for (final penalty in const ["none", "DNF", "+2"])
          MochiMenuItem(
            title: Text(penalty),
            selected: _penalty == penalty,
            onPress: () => setState(() {
              _penalty = penalty;
              _chosen = "penalty $penalty";
            }),
          ),
      ],
    ),
    const MochiMenuDivider(),
    MochiMenuItem(
      intent: MochiIntent.danger,
      prefix: const Icon(TablerIcons.trash),
      title: const Text("Delete"),
      onPress: () => setState(() => _chosen = "delete"),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Wrap(
      spacing: g.space.md,
      runSpacing: g.space.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        MochiPopoverMenu(
          menuBuilder: _items,
          builder: (context, anchor, _) => MochiButton(
            appearance: MochiButtonAppearance.outlined,
            size: MochiSize.sm,
            focusNode: anchor.focusNode,
            onPress: anchor.toggle,
            suffix: const Icon(TablerIcons.chevronDown),
            child: const Text("popover menu"),
          ),
        ),
        MochiPopoverMenu(
          menuBuilder: _items,
          builder: (context, anchor, _) => MochiButton.icon(
            appearance: MochiButtonAppearance.ghost,
            size: MochiSize.sm,
            focusNode: anchor.focusNode,
            onPress: anchor.toggle,
            icon: const Icon(TablerIcons.dotsVertical),
          ),
        ),
        MochiContextMenu(
          menuBuilder: _items,
          child: MochiCard(
            padding: EdgeInsets.symmetric(horizontal: g.space.md, vertical: g.space.sm),
            child: const Text("right click or long press me"),
          ),
        ),
        _ThemedText("chose: $_chosen", .muted),
      ],
    );
  }
}

class _DialogSample extends StatefulWidget {
  const _DialogSample();

  @override
  State<_DialogSample> createState() => _DialogSampleState();
}

class _DialogSampleState extends State<_DialogSample> {
  String _answer = "nothing yet";
  String _session = "3x3";

  Future<void> _confirm(BuildContext context) async {
    final answer = await showMochiDialog<bool>(
      context,
      builder: (context) => MochiDialog(
        title: const Text("Delete record?"),
        body: const Text("This record will be permanently deleted. There is no undo yet."),
        actions: [
          MochiButton(
            appearance: MochiButtonAppearance.outlined,
            onPress: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          MochiButton(
            intent: MochiIntent.danger,
            onPress: () => Navigator.of(context).pop(true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    setState(
      () => _answer = switch (answer) {
        true => "deleted",
        false => "cancelled",
        null => "dismissed",
      },
    );
  }

  Future<void> _modal(BuildContext context) async {
    final answer = await showMochiModal<bool>(
      context,
      title: const Text("Move to session?"),
      // On the title's own line, where what isn't an answer belongs.
      titleSuffix: MochiCloseButton(onPress: () => Navigator.of(context).pop()),
      body: const Text("Narrow the window to a phone width and this becomes a sheet."),
      actions: [
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          onPress: () => Navigator.of(context).pop(false),
          child: const Text("Cancel"),
        ),
        MochiButton(onPress: () => Navigator.of(context).pop(true), child: const Text("Move")),
      ],
    );
    if (!context.mounted) return;
    setState(
      () => _answer = switch (answer) {
        true => "moved",
        false => "cancelled",
        null => "dismissed",
      },
    );
  }

  Future<void> _long(BuildContext context) => showMochiDialog<void>(
    context,
    builder: (context) => MochiDialog(
      title: const Text("A long body scrolls"),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (var i = 1; i <= 40; i++) Text("Line $i of a body that outgrows the screen.")],
      ),
      actions: [MochiButton(onPress: () => Navigator.of(context).pop(), child: const Text("Close"))],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Wrap(
      spacing: g.space.md,
      runSpacing: g.space.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          size: MochiSize.sm,
          onPress: () => _confirm(context),
          child: const Text("confirm"),
        ),
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          size: MochiSize.sm,
          onPress: () => _long(context),
          child: const Text("long body"),
        ),
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          size: MochiSize.sm,
          onPress: () async {
            final yes = await showMochiConfirm(
              context,
              title: "Delete record?",
              message: "This record will be permanently deleted. There is no undo yet.",
              confirmLabel: "Delete",
              destructive: true,
            );
            if (!context.mounted) return;
            setState(() => _answer = yes ? "deleted" : "kept");
          },
          child: const Text("confirm helper"),
        ),
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          size: MochiSize.sm,
          onPress: () async {
            final picked = await showMochiChoice<String>(
              context,
              title: "Move to session",
              message: "Records move with the session they belong to.",
              selected: _session,
              choices: const [
                MochiChoice(value: "3x3", label: "3x3", icon: TablerIcons.cube),
                MochiChoice(value: "4x4", label: "4x4", description: "Bigger cube", icon: TablerIcons.cube),
                MochiChoice(value: "skewb", label: "Skewb", icon: TablerIcons.triangle, enabled: false),
              ],
            );
            if (!context.mounted || picked == null) return;
            setState(() {
              _session = picked;
              _answer = "moved to $picked";
            });
          },
          child: const Text("choice helper"),
        ),
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          size: MochiSize.sm,
          onPress: () async {
            await showMochiAlert(context, title: "Import finished", message: "42 records added.");
            if (!context.mounted) return;
            setState(() => _answer = "acknowledged");
          },
          child: const Text("alert helper"),
        ),
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          size: MochiSize.sm,
          onPress: () async {
            final name = await showMochiPrompt(
              context,
              title: "Rename session",
              initialValue: "3x3 main",
              maxLength: 24,
              validate: (value) => value.trim().isEmpty ? "A name can't be empty." : null,
            );
            if (!context.mounted) return;
            setState(() => _answer = name == null ? "kept the old name" : "renamed to $name");
          },
          child: const Text("prompt helper"),
        ),
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          size: MochiSize.sm,
          tooltip: "Dialog on a wide window, bottom sheet once it is phone-sized",
          onPress: () => _modal(context),
          child: const Text("adaptive modal"),
        ),
        _ThemedText("answer: $_answer", .muted),
      ],
    );
  }
}

class _SheetSample extends StatelessWidget {
  const _SheetSample();

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Wrap(
      spacing: g.space.sm,
      runSpacing: g.space.sm,
      children: [
        for (final side in MochiSheetSide.values)
          MochiButton(
            appearance: MochiButtonAppearance.outlined,
            size: MochiSize.sm,
            onPress: () => showMochiSheet<void>(
              context,
              side: side,
              builder: (context) => MochiSheet(
                side: side,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: g.space.sm,
                  children: [
                    Text("From the ${side.name}"),
                    const Text("Drag it towards its own edge to dismiss it, or press the barrier."),
                    MochiButton(
                      appearance: MochiButtonAppearance.soft,
                      onPress: () => Navigator.of(context).pop(),
                      child: const Text("Close"),
                    ),
                  ],
                ),
              ),
            ),
            child: Text(side.name),
          ),
      ],
    );
  }
}

class _ToastSample extends StatelessWidget {
  const _ToastSample();

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;

    return Wrap(
      spacing: g.space.sm,
      runSpacing: g.space.sm,
      children: [
        for (final intent in [
          MochiIntent.neutral,
          MochiIntent.success,
          MochiIntent.warning,
          MochiIntent.danger,
        ])
          MochiButton(
            appearance: MochiButtonAppearance.outlined,
            size: MochiSize.sm,
            onPress: () => showMochiToast(
              context,
              intent: intent,
              title: Text(switch (intent) {
                MochiIntent.success => "Saved",
                MochiIntent.warning => "Check your connection",
                MochiIntent.danger => "Could not save",
                _ => "Nothing to report",
              }),
            ),
            child: Text(intent.name),
          ),
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          size: MochiSize.sm,
          tooltip: "Hover it and it waits for you",
          onPress: () {
            late final MochiToastHandle handle;
            handle = showMochiToast(
              context,
              intent: MochiIntent.danger,
              icon: const Icon(TablerIcons.trash),
              title: const Text("Record deleted"),
              description: const Text("It is gone from this session."),
              action: MochiButton(
                appearance: MochiButtonAppearance.text,
                size: MochiSize.xs,
                onPress: () => handle.dismiss(),
                child: const Text("Undo"),
              ),
            );
          },
          child: const Text("with undo"),
        ),
        MochiButton(
          appearance: MochiButtonAppearance.outlined,
          size: MochiSize.sm,
          onPress: () {
            for (var i = 1; i <= 6; i++) {
              showMochiToast(context, title: Text("Message $i"), duration: const Duration(seconds: 3));
            }
          },
          child: const Text("six at once"),
        ),
      ],
    );
  }
}
