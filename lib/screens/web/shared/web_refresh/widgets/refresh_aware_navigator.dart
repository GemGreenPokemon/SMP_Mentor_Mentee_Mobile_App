import 'package:flutter/material.dart';
import '../controllers/refresh_controller.dart';

/// A navigator wrapper that tracks route changes and notifies refresh controllers
/// about visibility changes for background refresh management
class RefreshAwareNavigator extends StatefulWidget {
  final Widget child;
  final Map<String, RefreshController> controllers;
  final String? currentRoute;
  
  const RefreshAwareNavigator({
    Key? key,
    required this.child,
    required this.controllers,
    this.currentRoute,
  }) : super(key: key);
  
  @override
  State<RefreshAwareNavigator> createState() => _RefreshAwareNavigatorState();
}

class _RefreshAwareNavigatorState extends State<RefreshAwareNavigator> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _handleAppPaused();
        break;
      default:
        break;
    }
  }
  
  void _handleAppResumed() {
    // App came to foreground - resume refreshing for visible controllers
    if (widget.currentRoute != null) {
      widget.controllers.forEach((route, controller) {
        if (route == widget.currentRoute) {
          controller.setVisibility(true);
        }
      });
    }
  }
  
  void _handleAppPaused() {
    // App went to background - pause all controllers
    widget.controllers.forEach((route, controller) {
      controller.setVisibility(false);
    });
  }
  
  @override
  void didUpdateWidget(RefreshAwareNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if route changed
    if (oldWidget.currentRoute != widget.currentRoute) {
      _handleRouteChange(oldWidget.currentRoute, widget.currentRoute);
    }
  }
  
  void _handleRouteChange(String? oldRoute, String? newRoute) {
    // Mark old route controller as not visible
    if (oldRoute != null && widget.controllers.containsKey(oldRoute)) {
      widget.controllers[oldRoute]!.setVisibility(false);
    }
    
    // Mark new route controller as visible
    if (newRoute != null && widget.controllers.containsKey(newRoute)) {
      widget.controllers[newRoute]!.setVisibility(true);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Helper class to track routes for refresh management
class RefreshRouteObserver extends NavigatorObserver {
  final Function(String? from, String? to) onRouteChange;
  
  RefreshRouteObserver({required this.onRouteChange});
  
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChange(previousRoute?.settings.name, route.settings.name);
  }
  
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChange(route.settings.name, previousRoute?.settings.name);
  }
  
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    onRouteChange(oldRoute?.settings.name, newRoute?.settings.name);
  }
}