//stat view to show cat data as donut

//libraries
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

//internal asset files
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_card.dart';
import '../models/asset_model.dart';


class CategoryDonutCard extends StatelessWidget {
  const CategoryDonutCard({super.key, required this.counts});

  final Map<AssetCategory, int> counts;

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (a, b) => a + b);

    return SectionCard(
      title: 'Assets by category',
      child: total == 0
          ? const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('No assets to chart yet',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      )
          : Row(
        children: [
          SizedBox(
            height: 140,
            width: 140,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, t, __) => CustomPaint(
                painter: _DonutPainter(counts, total, t),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$total',
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w700)),
                      const Text('assets',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                for (final entry in counts.entries)
                  _LegendRow(
                    category: entry.key,
                    count: entry.value,
                    percent: (entry.value / total * 100).round(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.category,
    required this.count,
    required this.percent,
  });

  final AssetCategory category;
  final int count;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: category.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(category.label,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
          Text('$count',
              style:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          SizedBox(
            width: 34,
            child: Text('$percent%',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.counts, this.total, this.progress);

  final Map<AssetCategory, int> counts;
  final int total;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 20.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);

    // Track behind the segments.
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.fieldFill,
    );

    const gap = 0.05;
    var start = -math.pi / 2;
    counts.forEach((category, n) {
      final sweep = (n / total) * math.pi * 2 * progress;
      if (sweep > gap) {
        canvas.drawArc(
          rect,
          start,
          sweep - gap,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..color = category.color,
        );
      }
      start += sweep;
    });
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress ||
          old.total != total ||
          !mapEquals(old.counts, counts);
}