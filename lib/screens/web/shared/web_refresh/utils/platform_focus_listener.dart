import 'dart:async';

// Conditional imports
import 'platform_focus_listener_mobile.dart'
    if (dart.library.html) 'platform_focus_listener_web.dart' as impl;

/// Interface for platform-specific focus listeners
abstract class PlatformFocusListener {
  /// Listen for focus events
  StreamSubscription<void>? listenForFocus(void Function() onFocus);
  
  /// Create the appropriate implementation based on platform
  factory PlatformFocusListener() = impl.PlatformFocusListenerImpl;
}