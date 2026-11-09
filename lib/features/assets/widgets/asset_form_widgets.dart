//adding assets form ui

//libraries
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

//internal resource files
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_form_fields.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../dashboard/models/asset_model.dart';
import '../../dashboard/widgets/category_badge.dart';

// horizontal category chips at the top of the form.
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({super.key, required this.selected, required this.onChanged});

  final AssetCategory selected;
  final ValueChanged<AssetCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    const values = AssetCategory.values;
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final c = values[i];
          final isSelected = c == selected;
          return GestureDetector(
            onTap: () => onChanged(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 92,
              decoration: BoxDecoration(
                color: isSelected ? c.color.withValues(alpha: 0.12) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: isSelected ? c.color : AppColors.border,
                    width: isSelected ? 2 : 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CategoryBadge(category: c, size: 38),
                  const SizedBox(height: 6),
                  Text(c.label.split(' ').first,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// two photo slots (camera or gallery).
class PhotoSlots extends StatelessWidget {
  const PhotoSlots({
    super.key,
    required this.photos,
    required this.onChanged,
    this.existingUrls = const [null, null],
    this.showError = false,
  });

  final List<File?> photos;
  final List<String?> existingUrls;          // ← new
  final void Function(int index, File? file) onChanged;
  final bool showError;

  static const _labels = ['Main photo', 'Second photo'];

  Future<void> _pick(BuildContext context, int index) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picked = await ImagePicker()
          .pickImage(source: source, maxWidth: 1600, imageQuality: 75);
      if (picked != null) onChanged(index, File(picked.path));
    } on PlatformException {
      if (context.mounted) {
        AppSnackBar.show(
          context,
          'Could not open the camera or gallery. Check app permissions.',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < 2; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: _slot(context, i)),
            ],
          ],
        ),
        if (showError)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Please add both photos',
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _slot(BuildContext context, int index) {
    final file = photos[index];
    final url = existingUrls[index];
    final hasImage = file != null || (url != null && url.isNotEmpty);

    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTap: () => _pick(context, index),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.fieldFill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: showError && !hasImage ? AppColors.error : AppColors.border,
            ),
          ),
          child: !hasImage
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_a_photo_outlined,
                  color: AppColors.primary, size: 30),
              const SizedBox(height: 8),
              Text(
                _labels[index],
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          )
              : Stack(
            fit: StackFit.expand,
            children: [
              // Prefer local file, otherwise show the existing network image
              if (file != null)
                Image.file(file, fit: BoxFit.cover)
              else
                Image.network(
                  url!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => onChanged(index, null), // parent clears both file + url
                  child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close_rounded,
                        size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Vehicle service history: list + "Add service record".
class ServiceRecordsEditor extends StatelessWidget {
  const ServiceRecordsEditor({super.key, required this.records, required this.onChanged});

  final List<ServiceRecord> records;
  final ValueChanged<List<ServiceRecord>> onChanged;

  Future<void> _add(BuildContext context) async {
    final record = await showModalBottomSheet<ServiceRecord>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const _ServiceRecordSheet(),
    );
    if (record != null) onChanged([...records, record]);
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...records]..sort((a, b) => b.date.compareTo(a.date));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sorted.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('No service records yet (optional for new vehicles).',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ),
        for (final r in sorted)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.build_circle_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.description,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(
                        '${Formatters.shortDate(r.date)}'
                            '${r.cost > 0 ? ' · ${Formatters.currencyFull(r.cost)}' : ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => onChanged(records.where((x) => x != r).toList()),
                ),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => _add(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add service record'),
        ),
      ],
    );
  }
}

class _ServiceRecordSheet extends StatefulWidget {
  const _ServiceRecordSheet();

  @override
  State<_ServiceRecordSheet> createState() => _ServiceRecordSheetState();
}

class _ServiceRecordSheetState extends State<_ServiceRecordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _cost = TextEditingController();
  DateTime? _date;

  @override
  void dispose() {
    _description.dispose();
    _cost.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ServiceRecord(
        date: _date!,
        description: _description.text.trim(),
        cost: double.tryParse(_cost.text) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add service record',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
            AppDateField(
              label: 'Service date',
              value: _date,
              onChanged: (d) => _date = d,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
              isRequired: true,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _description,
              label: 'What was done?',
              icon: Icons.build_outlined,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => Validators.notEmpty(v, 'Description'),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _cost,
              label: 'Cost (Rs.), optional',
              icon: Icons.payments_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: amountFormatters,
              validator: (v) => Validators.amount(v, field: 'Cost', required: false),
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Add record', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}