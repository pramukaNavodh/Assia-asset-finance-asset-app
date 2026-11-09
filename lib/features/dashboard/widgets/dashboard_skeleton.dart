//the loading skeleton view for the dashboard

//libraries
import 'package:flutter/material.dart';

//internal resource files
import '../../../core/widgets/skeleton.dart';


class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              SkeletonBox(width: 110, height: 40, radius: 22),
              SizedBox(width: 8),
              SkeletonBox(width: 90, height: 40, radius: 22),
              SizedBox(width: 8),
              SkeletonBox(width: 90, height: 40, radius: 22),
            ],
          ),
          SizedBox(height: 20),
          SkeletonBox(height: 150, radius: 24),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 120, radius: 20)),
              SizedBox(width: 14),
              Expanded(child: SkeletonBox(height: 120, radius: 20)),
            ],
          ),
          SizedBox(height: 16),
          SkeletonBox(height: 190, radius: 24),
          SizedBox(height: 16),
          SkeletonBox(height: 300, radius: 24),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}