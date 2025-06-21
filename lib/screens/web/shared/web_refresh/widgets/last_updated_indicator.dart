import 'dart:async';
import 'package:flutter/material.dart';
import '../models/refresh_state.dart';

class LastUpdatedIndicator extends StatefulWidget {
  final DateTime lastRefresh;
  final VoidCallback? onRefresh;

  const LastUpdatedIndicator({
    Key? key,
    required this.lastRefresh,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<LastUpdatedIndicator> createState() => _LastUpdatedIndicatorState();
}

class _LastUpdatedIndicatorState extends State<LastUpdatedIndicator> {
  Timer? _timer;
  late RefreshState _state;

  @override
  void initState() {
    super.initState();
    _state = RefreshState(lastRefresh: widget.lastRefresh);
    _startTimer();
  }

  @override
  void didUpdateWidget(LastUpdatedIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lastRefresh != widget.lastRefresh) {
      setState(() {
        _state = RefreshState(lastRefresh: widget.lastRefresh);
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: widget.onRefresh,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.update,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                _state.lastRefreshDisplay,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}