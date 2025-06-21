import 'package:flutter/material.dart';
import '../controllers/refresh_controller.dart';
import 'pull_to_refresh_web.dart';
import 'web_refresh_wrapper.dart';
import 'last_updated_indicator.dart';

class RefreshableContainer<T> extends StatelessWidget {
  final RefreshController<T> controller;
  final Widget Function(BuildContext context, T? data) builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;
  final ScrollController? scrollController;

  const RefreshableContainer({
    Key? key,
    required this.controller,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
    this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;
        final data = controller.data;

        if (state.isInitialLoad) {
          return Center(
            child: loadingWidget ?? const CircularProgressIndicator(),
          );
        }

        if (state.hasError && data == null) {
          return Center(
            child: errorWidget ?? _buildDefaultError(context),
          );
        }

        if (data == null && emptyWidget != null) {
          return emptyWidget!;
        }

        return Stack(
          children: [
            if (controller.config.enablePullToRefresh)
              WebRefreshWrapper(
                onRefresh: controller.refresh,
                enabled: !state.isRefreshing,
                child: builder(context, data),
              )
            else
              builder(context, data),
            
            if (state.isRefreshing && controller.config.showRefreshIndicator)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(),
              ),
            
            if (controller.config.showLastUpdated && state.hasData)
              Positioned(
                top: 8,
                right: 8,
                child: LastUpdatedIndicator(
                  lastRefresh: state.lastRefresh!,
                  onRefresh: controller.refresh,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDefaultError(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          'Failed to load data',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          controller.state.error ?? 'An unknown error occurred',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: controller.refresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}