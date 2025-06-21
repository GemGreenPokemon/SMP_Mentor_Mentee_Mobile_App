import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A simpler refresh wrapper specifically for web that works with any content
class WebRefreshWrapper extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final bool enabled;

  const WebRefreshWrapper({
    Key? key,
    required this.child,
    required this.onRefresh,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<WebRefreshWrapper> createState() => _WebRefreshWrapperState();
}

class _WebRefreshWrapperState extends State<WebRefreshWrapper>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _rotationController;
  
  double _dragDistance = 0.0;
  bool _isRefreshing = false;
  static const double _triggerDistance = 80.0;
  static const double _maxDistance = 120.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled || _isRefreshing) return;
    
    setState(() {
      _dragDistance = (_dragDistance + details.delta.dy).clamp(0.0, _maxDistance);
      _controller.value = _dragDistance / _triggerDistance;
    });
  }

  void _handleDragEnd(DragEndDetails details) async {
    if (!widget.enabled || _isRefreshing) return;
    
    if (_dragDistance >= _triggerDistance) {
      setState(() {
        _isRefreshing = true;
      });
      
      _rotationController.repeat();
      
      try {
        await widget.onRefresh();
      } finally {
        if (mounted) {
          setState(() {
            _isRefreshing = false;
          });
          _rotationController.stop();
        }
      }
    }
    
    _controller.animateTo(0).then((_) {
      if (mounted) {
        setState(() {
          _dragDistance = 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content with gesture detector
        GestureDetector(
          onVerticalDragUpdate: _handleDragUpdate,
          onVerticalDragEnd: _handleDragEnd,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _dragDistance),
                child: widget.child,
              );
            },
          ),
        ),
        
        // Refresh indicator
        if (_dragDistance > 0 || _isRefreshing)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: _dragDistance,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              child: _dragDistance < _triggerDistance && !_isRefreshing
                  ? Icon(
                      Icons.arrow_downward,
                      size: 24,
                      color: Theme.of(context).primaryColor,
                    )
                  : AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationController.value * 2 * math.pi,
                          child: Icon(
                            Icons.refresh,
                            size: 24,
                            color: Theme.of(context).primaryColor,
                          ),
                        );
                      },
                    ),
            ),
          ),
      ],
    );
  }
}