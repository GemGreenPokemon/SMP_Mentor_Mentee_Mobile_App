import 'dart:async';
import 'platform_focus_listener.dart';

/// Mobile implementation of PlatformFocusListener
class PlatformFocusListenerImpl implements PlatformFocusListener {
  @override
  StreamSubscription<void>? listenForFocus(void Function() onFocus) {
    // Mobile apps don't have focus/blur events like web browsers
    // Return null to indicate no subscription
    return null;
  }
}