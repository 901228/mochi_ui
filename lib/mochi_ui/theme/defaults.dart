import "package:flutter/widgets.dart";

import "motion.dart";
import "size.dart";
import "styles/button_style.dart";
import "tone.dart";

/// Per-component defaults, so an app can set its own house style without passing the same
/// arguments everywhere:
///
/// ```dart
/// MochiTheme.light.copyWith(defaults: const MochiDefaults(buttonAppearance: .soft))
/// ```
///
/// Keep these identical in light and dark themes: a default that changes with brightness
/// makes the same code render with different emphasis depending on the theme.
@immutable
class MochiDefaults {
  const MochiDefaults({
    this.buttonIntent = MochiIntent.primary,
    this.buttonAppearance = MochiButtonAppearance.solid,
    this.iconButtonAppearance = MochiButtonAppearance.ghost,
    this.buttonSize = MochiSize.md,
    this.transition = MochiTransition.scaleFade,
  });

  final MochiIntent buttonIntent;
  final MochiButtonAppearance buttonAppearance;

  /// Used by [MochiButton.icon], which usually sits in toolbars rather than as a main action.
  final MochiButtonAppearance iconButtonAppearance;
  final MochiSize buttonSize;

  /// How pages and dialogs enter and leave, for the ones that are not told otherwise. A sheet
  /// always slides and a popover always grows out of its anchor: that is what makes them those
  /// things rather than a setting.
  final MochiTransition transition;

  static const standard = MochiDefaults();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MochiDefaults &&
          buttonIntent == other.buttonIntent &&
          buttonAppearance == other.buttonAppearance &&
          iconButtonAppearance == other.iconButtonAppearance &&
          buttonSize == other.buttonSize &&
          transition == other.transition;

  @override
  int get hashCode =>
      Object.hash(buttonIntent, buttonAppearance, iconButtonAppearance, buttonSize, transition);
}
