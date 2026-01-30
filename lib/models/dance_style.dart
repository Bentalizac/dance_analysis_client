/// Represents the type/style of dance being analyzed
///
/// This helps the backend apply style-specific pose requirements
/// and provide appropriate feedback.
enum DanceStyle {
  waltz,
  samba;

  /// Human-readable display name for the UI
  String get displayName => switch (this) {
    waltz => 'Waltz',
    samba => 'Samba',
  };

  /// Convert to JSON-compatible string
  String toJson() => name;

  /// Create from JSON string
  static DanceStyle fromJson(String value) {
    return DanceStyle.values.firstWhere(
      (style) => style.name == value,
      orElse: () => throw ArgumentError('Invalid dance style: $value'),
    );
  }
}
