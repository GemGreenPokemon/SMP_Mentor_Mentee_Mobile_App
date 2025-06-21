import 'package:flutter/material.dart';
import 'refresh_controller.dart';

mixin AutoRefreshMixin<T extends StatefulWidget> on State<T> {
  RefreshController? _controller;

  void setupAutoRefresh(RefreshController controller) {
    _controller = controller;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}