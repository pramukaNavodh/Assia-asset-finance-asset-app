//cardview for holding branch data

//libraries
import 'package:flutter/material.dart';

//internal resource file
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_card.dart';
import '../providers/dashboard_provider.dart';

// Horizontal bars: how many assets each branch holds
class BranchBarsCard extends StatelessWidget {
  const BranchBarsCard({super.key, required this.counts});

  final List<BranchCount> counts; // sorted, highest first

  @override
  Widget build(BuildContext context) {
    if (counts.isEmpty) return const SizedBox.shrink();
    final max = counts.first.count;

    return SectionCard(
      title: 'Assets by branch',
      child: Column(
        children: [
          for (final item in counts)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.branch.name,
                            style: const TextStyle(fontSize: 13)),
                      ),
                      Text('${item.count}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        Container(
                            height: 8,
                            width: double.infinity,
                            color: AppColors.fieldFill),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: item.count / max),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => FractionallySizedBox(
                            widthFactor: v,
                            child: Container(
                              height: 8,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.primary, AppColors.accent],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}