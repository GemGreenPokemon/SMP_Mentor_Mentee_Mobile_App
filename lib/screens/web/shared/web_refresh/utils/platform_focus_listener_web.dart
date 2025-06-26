import 'dart:async';
import 'dart:html' as html;
import 'platform_focus_listener.dart';

/// Web implementation of PlatformFocusListener
class PlatformFocusListenerImpl implements PlatformFocusListener {
  @override
  StreamSubscription<void>? listenForFocus(void Function() onFocus) {
    return html.window.onFocus.listen((_) {
      onFocus();
    });
  }
}