/// A floating island bottom navigation bar.
///
/// Each page asserts its own island layout through a [NavOverrideScope] and
/// the bar — mounted once, above the navigator — morphs between them: islands
/// slide in and out, the selection indicator stretches to its destination, and
/// chips that survive a page change change colour in place.
///
/// The package depends on Flutter alone, not even Material: state is a plain
/// [NavIslandsController], navigation is caller-supplied callbacks, glyphs are
/// painted by the caller through [NavIcon.custom], and colours come from
/// [NavIslandsThemeData].
library;

export 'src/nav_action_button.dart';
export 'src/nav_actions_fan.dart';
export 'src/nav_icon.dart';
export 'src/nav_island.dart';
export 'src/nav_islands_bar.dart';
export 'src/nav_islands_controller.dart';
export 'src/nav_islands_layout.dart';
export 'src/nav_islands_theme.dart';
export 'src/nav_item.dart';
export 'src/nav_item_chip.dart';
export 'src/nav_override_scope.dart';
export 'src/nav_pressable.dart';
export 'src/nav_single_action_bars.dart';
export 'src/nav_spinner.dart';
