//base add asset ui

//libraries
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

//internal resource files
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_form_fields.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/data/asset_repository.dart';
import '../../dashboard/models/asset_model.dart';
import '../../dashboard/models/branch_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../widgets/asset_form_widgets.dart';
import '../widgets/location_picker.dart';

class AddAssetScreen extends StatefulWidget {
  const AddAssetScreen({super.key, this.initial});

  final Asset? initial;

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();

  final List<String?> _existingUrls = [null, null];
  bool get _isEdit => widget.initial != null;

  String _num(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    if (a == null) return;
    _category = a.category;
    _branchId = Branches.byId(a.branchId) != null ? a.branchId : null;
    _title.text = a.title;
    _description.text = a.description;
    _price.text = _num(a.price);
    _dateObtained = a.dateObtained;
    _method = a.depreciationMethod;
    _life.text = a.usefulLifeYears?.toString() ?? '5';
    _salvage.text = a.salvageValue == 0 ? '' : _num(a.salvageValue);
    _hasWarranty = a.warrantyExpiry != null || a.warrantyProvider != null;
    _warrantyProvider.text = a.warrantyProvider ?? '';
    _warrantyExpiry = a.warrantyExpiry;
    _warrantyNotes.text = a.warrantyNotes ?? '';
    _serial.text = a.serialNumber ?? '';
    _manufacturer.text = a.manufacturer ?? '';
    _additionalInfo.text = a.additionalInfo ?? '';
    _plate.text = a.numberPlate ?? '';
    _insuranceProvider.text = a.insuranceProvider ?? '';
    _insurancePolicy.text = a.insurancePolicyNumber ?? '';
    _insuranceExpiry = a.insuranceExpiry;
    _records = [...a.serviceRecords];
    if (a.hasLocation) _location = LatLng(a.latitude!, a.longitude!);
    for (var i = 0; i < 2 && i < a.imageUrls.length; i++) {
      _existingUrls[i] = a.imageUrls[i];
    }
  }

  // Text inputs
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _life = TextEditingController(text: '5');
  final _salvage = TextEditingController();
  final _warrantyProvider = TextEditingController();
  final _warrantyNotes = TextEditingController();
  final _serial = TextEditingController();
  final _manufacturer = TextEditingController();
  final _additionalInfo = TextEditingController();
  final _plate = TextEditingController();
  final _insuranceProvider = TextEditingController();
  final _insurancePolicy = TextEditingController();

  // Other inputs
  AssetCategory _category = AssetCategory.furniture;
  String? _branchId;
  DateTime? _dateObtained;
  DepreciationMethod _method = DepreciationMethod.straightLine;
  bool _hasWarranty = false;
  DateTime? _warrantyExpiry;
  DateTime? _insuranceExpiry;
  List<ServiceRecord> _records = [];
  LatLng? _location;
  final List<File?> _photos = [null, null];

  bool _saving = false;
  bool _dirty = false;
  bool _photoError = false;
  bool _locationError = false;

  @override
  void dispose() {
    for (final c in [
      _title, _description, _price, _life, _salvage, _warrantyProvider, _warrantyNotes,
      _serial, _manufacturer, _additionalInfo, _plate, _insuranceProvider, _insurancePolicy,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _markDirty() => _dirty = true;

  String? _text(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  double? get _estimatedValue {
    final price = double.tryParse(_price.text);
    final date = _dateObtained;
    if (price == null || date == null || _method == DepreciationMethod.none) return null;
    return depreciatedValue(
      price: price,
      obtained: date,
      method: _method,
      usefulLifeYears: int.tryParse(_life.text),
      salvageValue: double.tryParse(_salvage.text) ?? 0,
    );
  }

  Asset _buildAsset() {
    final isDevice = _category.isDevice;
    final isVehicle = _category == AssetCategory.vehicle;
    final withDepreciation = _method != DepreciationMethod.none;

    return Asset(
      id: widget.initial?.id ?? '',
      title: _title.text.trim(),
      description: _description.text.trim(),
      category: _category,
      price: double.parse(_price.text),
      branchId: _branchId!,
      dateObtained: _dateObtained!,
      latitude: _location!.latitude,
      longitude: _location!.longitude,
      depreciationMethod: _method,
      usefulLifeYears: withDepreciation ? int.tryParse(_life.text) : null,
      salvageValue: withDepreciation ? (double.tryParse(_salvage.text) ?? 0) : 0,
      warrantyProvider: _hasWarranty ? _text(_warrantyProvider) : null,
      warrantyExpiry: _hasWarranty ? _warrantyExpiry : null,
      warrantyNotes: _hasWarranty ? _text(_warrantyNotes) : null,
      serialNumber: isDevice ? _text(_serial) : null,
      manufacturer: isDevice ? _text(_manufacturer) : null,
      additionalInfo: isDevice ? _text(_additionalInfo) : null,
      numberPlate: isVehicle ? _plate.text.trim().toUpperCase() : null,
      insuranceProvider: isVehicle ? _text(_insuranceProvider) : null,
      insurancePolicyNumber: isVehicle ? _text(_insurancePolicy) : null,
      insuranceExpiry: isVehicle ? _insuranceExpiry : null,
      serviceRecords: isVehicle ? _records : const [],
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final formOk = _formKey.currentState!.validate();
    final photosOk =
    List.generate(2, (i) => _photos[i] != null || _existingUrls[i] != null).every((ok) => ok);
    final locationOk = _location != null;
    setState(() {
      _photoError = !photosOk;
      _locationError = !locationOk;
    });
    if (!formOk || !photosOk || !locationOk) {
      AppSnackBar.show(context, 'Please complete the highlighted fields.', isError: true);
      return;
    }

    final auth = context.read<AuthProvider>();
    final dashboard = context.read<DashboardProvider>();
    final userId = auth.user?.uid;
    if (userId == null) {
      AppSnackBar.show(context, 'Please sign in again.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await dashboard.updateAsset(
          _buildAsset(),
          newImages: {
            for (var i = 0; i < 2; i++)
              if (_photos[i] != null) i: _photos[i]!,
          },
          keptUrls: _existingUrls,
        );
      } else {
        await dashboard.addAsset(
          _buildAsset(),
          images: _photos.whereType<File>().toList(),
          userId: userId,
          userName: auth.displayName,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on AssetSaveFailure catch (e) {
      if (mounted) AppSnackBar.show(context, e.message, isError: true);
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(context, 'Something went wrong. Please try again.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onBack() async {
    if (_saving) return;
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Discard this asset?'),
        content: const Text('Everything you entered will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep editing')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard')),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  List<Widget> _spaced(List<Widget> items) => [
    for (var i = 0; i < items.length; i++) ...[
      if (i > 0) const SizedBox(height: 14),
      items[i],
    ],
  ];

  Widget _section(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: SectionCard(title: title, child: Column(children: _spaced(children))),
  );

  @override
  Widget build(BuildContext context) {
    final branch = Branches.byId(_branchId);
    final branchPoint = branch == null ? null : LatLng(branch.latitude, branch.longitude);
    final estimated = _estimatedValue;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Edit asset' : 'Add asset'),
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
        ),
        body: Form(
          key: _formKey,
          onChanged: _markDirty,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              const Text('What are you adding?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              CategoryPicker(
                selected: _category,
                onChanged: (c) => setState(() {
                  _category = c;
                  _dirty = true;
                }),
              ),
              const SizedBox(height: 20),

              _section('Basic details', [
                AppTextField(
                  controller: _title,
                  label: 'Asset title',
                  icon: Icons.label_outline_rounded,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final empty = Validators.notEmpty(v, 'Title');
                    if (empty != null) return empty;
                    return v!.trim().length > 80 ? 'Keep the title under 80 characters' : null;
                  },
                ),
                AppTextField(
                  controller: _description,
                  label: 'Description (optional)',
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                AppDropdownField<String>(
                  label: 'Branch',
                  icon: Icons.store_mall_directory_outlined,
                  value: _branchId,
                  items: [
                    for (final b in Branches.all)
                      DropdownMenuItem(value: b.id, child: Text(b.name)),
                  ],
                  onChanged: (v) => setState(() {
                    _branchId = v;
                    _dirty = true;
                  }),
                  validator: (v) => v == null ? 'Select a branch' : null,
                ),
                AppTextField(
                  controller: _price,
                  label: 'Purchase price (Rs.)',
                  icon: Icons.payments_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: amountFormatters,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  validator: (v) => Validators.amount(v, field: 'Price'),
                ),
                AppDateField(
                  label: 'Date obtained',
                  value: _dateObtained,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  isRequired: true,
                  onChanged: (d) => setState(() {
                    _dateObtained = d;
                    _dirty = true;
                  }),
                ),
              ]),

              _section('Depreciation', [
                AppDropdownField<DepreciationMethod>(
                  label: 'Method',
                  icon: Icons.trending_down_rounded,
                  value: _method,
                  items: [
                    for (final m in DepreciationMethod.values)
                      DropdownMenuItem(value: m, child: Text(m.label)),
                  ],
                  onChanged: (v) => setState(() {
                    _method = v ?? DepreciationMethod.none;
                    _dirty = true;
                  }),
                ),
                if (_method != DepreciationMethod.none)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _life,
                          label: 'Useful life (yrs)',
                          icon: Icons.hourglass_bottom_rounded,
                          keyboardType: TextInputType.number,
                          inputFormatters: digitsFormatters,
                          onChanged: (_) => setState(() {}),
                          validator: (v) =>
                              Validators.wholeNumber(v, field: 'Useful life', min: 1, max: 50),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          controller: _salvage,
                          label: 'Salvage (Rs.)',
                          icon: Icons.savings_outlined,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: amountFormatters,
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final err = Validators.amount(v, field: 'Salvage', required: false);
                            if (err != null) return err;
                            final s = double.tryParse(v ?? '');
                            final p = double.tryParse(_price.text);
                            return (s != null && p != null && s > p) ? 'Above price' : null;
                          },
                        ),
                      ),
                    ],
                  ),
                if (estimated != null) _ValuePreview(value: estimated),
              ]),

              _section('Warranty', [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Covered by warranty'),
                  value: _hasWarranty,
                  onChanged: (v) => setState(() {
                    _hasWarranty = v;
                    _dirty = true;
                  }),
                ),
                if (_hasWarranty) ...[
                  AppTextField(
                    controller: _warrantyProvider,
                    label: 'Warranty provider',
                    icon: Icons.verified_outlined,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => Validators.notEmpty(v, 'Provider'),
                  ),
                  AppDateField(
                    label: 'Warranty expires',
                    value: _warrantyExpiry,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
                    isRequired: true,
                    icon: Icons.event_available_outlined,
                    onChanged: (d) => setState(() => _warrantyExpiry = d),
                  ),
                  AppTextField(
                    controller: _warrantyNotes,
                    label: 'Terms / notes (optional)',
                    icon: Icons.description_outlined,
                    maxLines: 2,
                  ),
                ],
              ]),

              if (_category.isDevice)
                _section('Device details', [
                  AppTextField(
                    controller: _serial,
                    label: 'Serial number',
                    icon: Icons.qr_code_2_rounded,
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) => Validators.notEmpty(v, 'Serial number'),
                  ),
                  AppTextField(
                    controller: _manufacturer,
                    label: 'Manufacturer',
                    icon: Icons.factory_outlined,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => Validators.notEmpty(v, 'Manufacturer'),
                  ),
                  AppTextField(
                    controller: _additionalInfo,
                    label: 'Additional information (optional)',
                    icon: Icons.info_outline_rounded,
                    maxLines: 3,
                  ),
                ]),

              if (_category == AssetCategory.vehicle)
                _section('Vehicle details', [
                  AppTextField(
                    controller: _plate,
                    label: 'Number plate',
                    icon: Icons.pin_outlined,
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) => Validators.notEmpty(v, 'Number plate'),
                  ),
                  AppTextField(
                    controller: _insuranceProvider,
                    label: 'Insurance provider',
                    icon: Icons.shield_outlined,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => Validators.notEmpty(v, 'Insurance provider'),
                  ),
                  AppTextField(
                    controller: _insurancePolicy,
                    label: 'Policy number (optional)',
                    icon: Icons.confirmation_number_outlined,
                  ),
                  AppDateField(
                    label: 'Insurance expires',
                    value: _insuranceExpiry,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                    isRequired: true,
                    icon: Icons.event_available_outlined,
                    onChanged: (d) => setState(() => _insuranceExpiry = d),
                  ),
                  ServiceRecordsEditor(
                    records: _records,
                    onChanged: (r) => setState(() {
                      _records = r;
                      _dirty = true;
                    }),
                  ),
                  const Text(
                    'Live location sharing is switched on from the vehicle page (a later phase).',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ]),

              _section('Location', [
                LocationField(
                  location: _location,
                  branchPoint: branchPoint,
                  branchName: branch?.name,
                  showError: _locationError,
                  onChanged: (l) => setState(() {
                    _location = l;
                    _locationError = false;
                    _dirty = true;
                  }),
                ),
              ]),

              _section('Photos', [
                const Text('Add two clear photos of the asset.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                PhotoSlots(
                  photos: _photos,
                  existingUrls: _existingUrls,
                  showError: _photoError,
                  onChanged: (i, file) => setState(() {
                    _photos[i] = file;
                    if (file == null) _existingUrls[i] = null;
                    _photoError = false;
                    _dirty = true;
                  }),
                ),
              ]),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: PrimaryButton(
              label: _isEdit ? 'Save changes' : 'Save asset',
              icon: Icons.check_rounded,
              isLoading: _saving,
              onPressed: _save,
            ),
          ),
        ),
      ),
    );
  }
}

/// Live "estimated value today" hint under the depreciation fields.
class _ValuePreview extends StatelessWidget {
  const _ValuePreview({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights_rounded, color: AppColors.success),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Estimated value today', style: TextStyle(fontSize: 13)),
          ),
          Text(Formatters.currencyFull(value),
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}