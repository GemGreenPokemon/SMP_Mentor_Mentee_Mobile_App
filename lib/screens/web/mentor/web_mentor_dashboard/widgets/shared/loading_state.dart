import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../utils/dashboard_constants.dart';

class LoadingState extends StatefulWidget {
  const LoadingState({super.key});

  @override
  State<LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<LoadingState> 
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: DashboardDurations.fadeAnimation,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: DashboardCurves.smoothCurve,
    ));
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Shimmer.fromColors(
            baseColor: DashboardColors.borderLight,
            highlightColor: DashboardColors.backgroundLight,
            period: DashboardDurations.shimmerAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DashboardSizes.spacingLarge),
              child: Column(
                children: [
                  // First row shimmer
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mentees section placeholder
                      Expanded(
                        flex: 2,
                        child: _buildShimmerCard(height: 300),
                      ),
                      const SizedBox(width: DashboardSizes.spacingLarge),
                      // Meetings section placeholder
                      Expanded(
                        flex: 3,
                        child: _buildShimmerCard(height: 300),
                      ),
                    ],
                  ),
                  const SizedBox(height: DashboardSizes.spacingLarge),
                  // Second row shimmer
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Announcements section placeholder
                      Expanded(
                        flex: 3,
                        child: _buildShimmerCard(height: 250),
                      ),
                      const SizedBox(width: DashboardSizes.spacingLarge),
                      // Activity section placeholder
                      Expanded(
                        flex: 2,
                        child: _buildShimmerCard(height: 250),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: DashboardColors.backgroundWhite,
        borderRadius: BorderRadius.circular(DashboardSizes.borderRadiusMedium),
        boxShadow: DashboardShadows.cardShadow,
      ),
      padding: const EdgeInsets.all(DashboardSizes.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header placeholder
          Container(
            height: 24,
            width: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: DashboardSizes.spacingMedium),
          // Content placeholders
          Expanded(
            child: Column(
              children: List.generate(3, (index) => Padding(
                padding: const EdgeInsets.only(bottom: DashboardSizes.spacingSmall),
                child: _buildShimmerRow(),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerRow() {
    return Row(
      children: [
        // Icon placeholder
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(width: DashboardSizes.spacingSmall),
        // Text placeholders
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 12,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}