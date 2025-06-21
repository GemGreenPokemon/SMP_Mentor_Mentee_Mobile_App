import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class PullToRefreshWeb extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final ScrollController? scrollController;
  final double triggerDistance;

  const PullToRefreshWeb({
    Key? key,
    required this.child,
    required this.onRefresh,
    this.scrollController,
    this.triggerDistance = 100.0,
  }) : super(key: key);

  @override
  State<PullToRefreshWeb> createState() => _PullToRefreshWebState();
}

class _PullToRefreshWebState extends State<PullToRefreshWeb>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _positionController;
  late AnimationController _rotationController;
  
  double _dragOffset = 0.0;
  bool _isRefreshing = false;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _positionController = AnimationController(
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
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    _positionController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    // For web, we need to check if we're at the top of the scroll view
    // If there's no scroll controller attached, assume we can pull to refresh
    bool canStartDrag = false;
    
    try {
      if (_scrollController.hasClients) {
        canStartDrag = _scrollController.position.pixels <= 0;
      } else {
        // No scroll position available, allow pull to refresh
        canStartDrag = true;
      }
    } catch (e) {
      // If there's any error checking scroll position, allow pull to refresh
      canStartDrag = true;
    }
    
    if (canStartDrag && !_isRefreshing) {
      setState(() {
        _isDragging = true;
      });
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_isDragging && event.delta.dy > 0) {
      setState(() {
        _dragOffset = math.min(_dragOffset + event.delta.dy, widget.triggerDistance * 1.5);
      });
      _positionController.value = _dragOffset / widget.triggerDistance;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_isDragging) {
      setState(() {
        _isDragging = false;
      });

      if (_dragOffset >= widget.triggerDistance && !_isRefreshing) {
        _triggerRefresh();
      } else {
        _resetPosition();
      }
    }
  }

  Future<void> _triggerRefresh() async {
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
        _resetPosition();
      }
    }
  }

  void _resetPosition() {
    _positionController.animateTo(0).then((_) {
      if (mounted) {
        setState(() {
          _dragOffset = 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _positionController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _dragOffset),
                child: widget.child,
              );
            },
          ),
          
          if (_dragOffset > 0 || _isRefreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: _dragOffset,
                alignment: Alignment.center,
                child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationController.value * 2 * math.pi,
                      child: Icon(
                        Icons.refresh,
                        size: 30,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}