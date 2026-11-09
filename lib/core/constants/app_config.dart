//as a fallback solution if any case assets don't appear in UI

class AppConfig {
  AppConfig._();

  // true  = built-in sample assets
  // false = read the real `assets` collection
  static const bool useDemoData = false;

  // Sent to the map tile server.
  static const String mapUserAgentPackage = 'com.pramuka.aafassets';
}