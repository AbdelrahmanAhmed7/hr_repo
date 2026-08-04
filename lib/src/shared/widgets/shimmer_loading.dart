import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: child,
    );
  }
}

class ShimmerPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? color;

  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class HomeShimmerLoading extends StatelessWidget {
  const HomeShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header Shimmer
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Today Attendance Card Shimmer
                  const ShimmerPlaceholder(width: double.infinity, height: 120, borderRadius: 16),
                  const SizedBox(height: 24),
                  // Quick Actions Shimmer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (index) => const ShimmerPlaceholder(width: 70, height: 90, borderRadius: 12)),
                  ),
                  const SizedBox(height: 32),
                  // Statistics Shimmer
                  Row(
                    children: [
                      Expanded(child: const ShimmerPlaceholder(width: double.infinity, height: 100, borderRadius: 16)),
                      const SizedBox(width: 16),
                      Expanded(child: const ShimmerPlaceholder(width: double.infinity, height: 100, borderRadius: 16)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Recent Activity Shimmer
                  const ShimmerPlaceholder(width: 150, height: 24, borderRadius: 4),
                  const SizedBox(height: 16),
                  ...List.generate(3, (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: const ShimmerPlaceholder(width: double.infinity, height: 70, borderRadius: 12),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileShimmerLoading extends StatelessWidget {
  const ProfileShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    // Keep the profile shimmer lightweight.
    // A single background avoids the screen looking "split in half" while loading.
    final base = Colors.grey.shade400;
    final highlight = Colors.grey.shade200;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          color: const Color(0xFF0B1734),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  ShimmerPlaceholder(
                    width: 110,
                    height: 14,
                    borderRadius: 6,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                  const SizedBox(height: 18),

                  // Avatar + name lines
                  Row(
                    children: [
                      ShimmerPlaceholder(
                        width: 72,
                        height: 72,
                        borderRadius: 24,
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerPlaceholder(
                              width: double.infinity,
                              height: 18,
                              borderRadius: 8,
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                            const SizedBox(height: 10),
                            ShimmerPlaceholder(
                              width: 180,
                              height: 14,
                              borderRadius: 999,
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                            const SizedBox(height: 10),
                            ShimmerPlaceholder(
                              width: 220,
                              height: 12,
                              borderRadius: 8,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // A few lightweight blocks (no "sheet" split)
                  ShimmerPlaceholder(
                    width: double.infinity,
                    height: 56,
                    borderRadius: 20,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                  const SizedBox(height: 12),
                  ShimmerPlaceholder(
                    width: double.infinity,
                    height: 110,
                    borderRadius: 20,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  const SizedBox(height: 12),
                  ShimmerPlaceholder(
                    width: double.infinity,
                    height: 110,
                    borderRadius: 20,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  const SizedBox(height: 12),
                  ShimmerPlaceholder(
                    width: double.infinity,
                    height: 90,
                    borderRadius: 20,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ListShimmerLoading extends StatelessWidget {
  final int itemCount;
  
  const ListShimmerLoading({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return const ShimmerPlaceholder(
            width: double.infinity,
            height: 90,
            borderRadius: 16,
          );
        },
      ),
    );
  }
}
