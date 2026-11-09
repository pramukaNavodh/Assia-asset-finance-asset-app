//report viewable ui

//libraries
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

//internal resource files
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_form_fields.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/skeleton.dart';
import '../../dashboard/models/asset_model.dart';
import '../../dashboard/models/branch_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/widgets/category_donut_card.dart';
import '../models/report_models.dart';
import '../services/report_pdf_builder.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportType _type = ReportType.register;
  String? _branchId;
  AssetCategory? _category;
  DateTimeRange? _range;
  bool _busy = false;

  String get _branchLabel => Branches.byId(_branchId)?.name ?? 'All branches';
  String get _categoryLabel => _category?.label ?? 'All categories';
  String get _rangeLabel => _range == null
      ? 'Any date'
      : '${Formatters.shortDate(_range!.start)} - ${Formatters.shortDate(_range!.end)}';

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  Future<void> _export(ReportData data, {required bool share}) async {
    setState(() => _busy = true);
    try {
      final bytes = await buildReportPdf(
        type: _type,
        data: data,
        branchLabel: _branchLabel,
        categoryLabel: _categoryLabel,
        rangeLabel: _rangeLabel,
      );
      final name = 'aaf_${_type.name}_report';
      if (share) {
        await Printing.sharePdf(bytes: bytes, filename: '$name.pdf');
      } else {
        await Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
      }
    } catch (e) {
      debugPrint('Report export failed: $e');
      if (mounted) {
        AppSnackBar.show(context, 'Could not create the report. Please try again.',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DashboardProvider>();
    final data = ReportData.build(p.allAssets,
        branchId: _branchId, category: _category, range: _range);
    final hasData = _type == ReportType.expiries ? data.expiries.isNotEmpty : data.assets.isNotEmpty;
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reports',
                    style: TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Choose a report, filter it, then share or print the PDF.',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: p.status == DashboardStatus.loading
                ? const Column(children: [
              SkeletonBox(height: 80, radius: 20),
              SizedBox(height: 12),
              SkeletonBox(height: 80, radius: 20),
              SizedBox(height: 12),
              SkeletonBox(height: 220, radius: 24),
            ])
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final t in ReportType.values)
                  _TypeTile(
                    type: t,
                    selected: t == _type,
                    onTap: () => setState(() => _type = t),
                  ),
                const SizedBox(height: 8),
                SectionCard(
                  title: 'Filters',
                  child: Column(
                    children: [
                      AppDropdownField<String?>(
                        label: 'Branch',
                        icon: Icons.store_mall_directory_outlined,
                        value: _branchId,
                        items: [
                          const DropdownMenuItem<String?>(
                              value: null, child: Text('All branches')),
                          for (final b in Branches.all)
                            DropdownMenuItem<String?>(value: b.id, child: Text(b.name)),
                        ],
                        onChanged: (v) => setState(() => _branchId = v),
                      ),
                      const SizedBox(height: 14),
                      AppDropdownField<AssetCategory?>(
                        label: 'Category',
                        icon: Icons.category_outlined,
                        value: _category,
                        items: [
                          const DropdownMenuItem<AssetCategory?>(
                              value: null, child: Text('All categories')),
                          for (final c in AssetCategory.values)
                            DropdownMenuItem<AssetCategory?>(
                                value: c, child: Text(c.label)),
                        ],
                        onChanged: (v) => setState(() => _category = v),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _pickRange,
                        child: InputDecorator(
                          decoration: appInputDecoration(
                            label: 'Acquired between',
                            icon: Icons.date_range_outlined,
                            suffixIcon: _range == null
                                ? const Icon(Icons.calendar_month_outlined, size: 18)
                                : IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () => setState(() => _range = null),
                            ),
                          ),
                          child: Text(_rangeLabel),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Preview(type: _type, data: data),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Share PDF',
                  icon: Icons.ios_share_rounded,
                  isLoading: _busy,
                  onPressed: hasData ? () => _export(data, share: true) : null,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: (hasData && !_busy) ? () => _export(data, share: false) : null,
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Preview / Print'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
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

class _TypeTile extends StatelessWidget {
  const _TypeTile({required this.type, required this.selected, required this.onTap});

  final ReportType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.withValues(alpha: 0.07) : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(type.icon, color: selected ? AppColors.primary : AppColors.textMuted),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type.label,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(type.description,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle_rounded, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// On-screen summary of what the PDF will contain.
class _Preview extends StatelessWidget {
  const _Preview({required this.type, required this.data});

  final ReportType type;
  final ReportData data;

  @override
  Widget build(BuildContext context) {
    final isExpiry = type == ReportType.expiries;
    final empty = isExpiry ? data.expiries.isEmpty : data.assets.isEmpty;

    if (empty) {
      return const SectionCard(
        title: 'Preview',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text('No records match these filters.',
                style: TextStyle(color: AppColors.textMuted)),
          ),
        ),
      );
    }

    final stats = isExpiry
        ? [
      ('Expired', '${data.expiries.where((e) => e.daysLeft < 0).length}'),
      ('Due in 30 days',
      '${data.expiries.where((e) => e.daysLeft >= 0 && e.daysLeft <= 30).length}'),
      ('Due in 90 days', '${data.expiries.where((e) => e.daysLeft > 30).length}'),
      ('Total items', '${data.expiries.length}'),
    ]
        : [
      ('Assets', Formatters.number(data.assets.length)),
      ('Purchase value', Formatters.currencyCompact(data.totalPurchase)),
      ('Current value', Formatters.currencyCompact(data.totalCurrent)),
      ('Depreciation', Formatters.currencyCompact(data.totalDepreciation)),
    ];

    final totalRows = isExpiry
        ? data.expiries.length
        : (type == ReportType.valuation ? data.valuation.length : data.assets.length);
    const shown = 5;

    return Column(
      children: [
        SectionCard(
          title: 'Preview',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final (label, value) in stats)
                    Container(
                      width: (MediaQuery.of(context).size.width - 40 - 40 - 10) / 2,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Text(value,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (isExpiry)
                for (final e in data.expiries.take(shown))
                  _row('${e.asset.title} (${e.kind})',
                      e.daysLeft < 0 ? 'Expired' : 'In ${e.daysLeft} d',
                      e.daysLeft < 0 ? AppColors.error : AppColors.textPrimary)
              else if (type == ReportType.valuation)
                for (final v in data.valuation.take(shown))
                  _row('${v.category.label} (${v.count})',
                      Formatters.currencyCompact(v.current), AppColors.textPrimary)
              else
                for (final a in data.assets.take(shown))
                  _row(a.title, Formatters.currencyCompact(a.currentValue), AppColors.textPrimary),
              if (totalRows > shown)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('+ ${totalRows - shown} more rows in the PDF',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ),
            ],
          ),
        ),
        if (!isExpiry) ...[
          const SizedBox(height: 16),
          CategoryDonutCard(counts: data.categoryCounts),
        ],
      ],
    );
  }

  Widget _row(String left, String right, Color rightColor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13)),
        ),
        Text(right,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: rightColor)),
      ],
    ),
  );
}