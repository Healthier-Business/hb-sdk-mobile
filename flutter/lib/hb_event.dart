import 'dart:convert';

/// One event the page passes to the app. [data] is what the frame sent, as plain JSON.
class HbEvent {
  /// `ready`, `progress`, `completed`, `passed`, `failed`, `submitted`, `terms-accepted` or `error`. A page may send others.
  final String name;
  final Map<String, dynamic> data;

  const HbEvent(this.name, this.data);

  /// The events that finish a session. Read the result from your server before you grant anything.
  static const finalNames = {'completed', 'passed', 'failed', 'submitted'};

  bool get isFinal => finalNames.contains(name);

  /// Reads the text the page sent. Returns null for anything that is not `{"name": "...", "data": {...}}`,
  /// so a stray message never reaches your app.
  static HbEvent? parse(String text) {
    if (text.length > 20000) {
      return null;
    }
    try {
      final value = jsonDecode(text);
      if (value is! Map) {
        return null;
      }
      final name = value['name'];
      if (name is! String || name.isEmpty || name.length > 64) {
        return null;
      }
      final data = value['data'];
      return HbEvent(name, data is Map ? data.cast<String, dynamic>() : <String, dynamic>{});
    } catch (_) {
      return null;
    }
  }
}
