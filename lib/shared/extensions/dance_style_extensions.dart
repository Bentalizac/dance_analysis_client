import '../../generated/api/models/dance_style.dart';

extension DanceStyleDisplay on DanceStyle {
  /// Human-readable label, e.g. `cha_cha` → `Cha Cha`.
  String get displayName {
    final raw = json ?? name;
    return raw
        .split('_')
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  DanceCategory get category => switch (this) {
    DanceStyle.waltz ||
    DanceStyle.tango ||
    DanceStyle.vienneseWaltz ||
    DanceStyle.foxtrot ||
    DanceStyle.quickstep => DanceCategory.standard,
    DanceStyle.samba ||
    DanceStyle.chaCha ||
    DanceStyle.rumba ||
    DanceStyle.pasoDoble ||
    DanceStyle.jive => DanceCategory.latin,
    DanceStyle.americanWaltz ||
    DanceStyle.americanTango ||
    DanceStyle.americanFoxtrot ||
    DanceStyle.americanVienneseWaltz => DanceCategory.smooth,
    _ => DanceCategory.rhythm,
  };
}

enum DanceCategory {
  standard('Standard'),
  latin('Latin'),
  smooth('American Smooth'),
  rhythm('American Rhythm');

  const DanceCategory(this.displayName);
  final String displayName;
}
