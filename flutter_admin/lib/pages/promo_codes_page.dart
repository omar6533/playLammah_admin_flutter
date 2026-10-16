import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/promo_code_model.dart';
import '../services/store_service.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_data_table.dart';
import '../widgets/empty_state.dart';

final _dateFmt = DateFormat('MMM dd, yyyy');

String _statusOf(PromoCodeModel p) {
  if (!p.isActive) return 'Disabled';
  if (p.isExpired) return 'Expired';
  if (p.isUsedUp) return 'Used up';
  return 'Active';
}

@RoutePage()
class PromoCodesPage extends StatefulWidget {
  const PromoCodesPage({super.key});

  @override
  State<PromoCodesPage> createState() => _PromoCodesPageState();
}

class _PromoCodesPageState extends State<PromoCodesPage> {
  final _service = StoreService();

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.success,
    ));
  }

  Future<void> _openEditor([PromoCodeModel? promo]) async {
    final saved = await showDialog<PromoCodeModel>(
      context: context,
      builder: (_) => _PromoDialog(initial: promo, service: _service),
    );
    if (saved == null) return;
    try {
      if (promo == null) {
        await _service.createPromoCode(saved);
        _snack('Promo code ${saved.code} created');
      } else {
        await _service.updatePromoCode(saved);
        _snack('Promo code ${saved.code} updated');
      }
    } catch (e) {
      _snack('Save failed: $e', error: true);
    }
  }

  Future<void> _delete(PromoCodeModel promo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete promo code'),
        content: Text('Delete "${promo.code}"? Customers won\'t be able to use it anymore.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deletePromoCode(promo.code);
      _snack('Promo code deleted');
    } catch (e) {
      _snack('Delete failed: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Promo Codes',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      SizedBox(height: 4),
                      Text('Discount codes customers can enter when buying a package.',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                CustomButton(text: 'Add Promo Code', icon: Icons.add, onPressed: () => _openEditor()),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<List<PromoCodeModel>>(
                stream: _service.watchPromoCodes(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(
                        child: Text('Error: ${snap.error}', style: const TextStyle(color: AppColors.danger)));
                  }
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final promos = snap.data!;
                  if (promos.isEmpty) {
                    return const EmptyState(
                      icon: Icons.local_offer_outlined,
                      title: 'No promo codes',
                      message: 'Create a code to give customers a discount.',
                    );
                  }
                  return CustomDataTable(
                    columns: const ['Code', 'Discount', 'Status', 'Uses', 'Expires'],
                    rows: promos
                        .map((p) => [
                              p.code,
                              '${p.discountPercent}%',
                              _statusOf(p),
                              p.maxUses == null ? '${p.usedCount} / ∞' : '${p.usedCount} / ${p.maxUses}',
                              p.expiresAt == null ? 'Never' : _dateFmt.format(p.expiresAt!),
                            ])
                        .toList(),
                    onEdit: (i) => _openEditor(promos[i]),
                    onDelete: (i) => _delete(promos[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoDialog extends StatefulWidget {
  final PromoCodeModel? initial;
  final StoreService service;

  const _PromoDialog({this.initial, required this.service});

  @override
  State<_PromoDialog> createState() => _PromoDialogState();
}

class _PromoDialogState extends State<_PromoDialog> {
  final _form = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.initial?.code ?? '');
  late final _percent = TextEditingController(text: widget.initial?.discountPercent.toString() ?? '');
  late final _maxUses = TextEditingController(text: widget.initial?.maxUses?.toString() ?? '');
  late bool _active = widget.initial?.isActive ?? true;
  late DateTime? _expires = widget.initial?.expiresAt;
  String? _codeError;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void dispose() {
    _code.dispose();
    _percent.dispose();
    _maxUses.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expires ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      // Valid through the end of the chosen day.
      setState(() => _expires = DateTime(picked.year, picked.month, picked.day, 23, 59, 59));
    }
  }

  Future<void> _submit() async {
    setState(() => _codeError = null);
    if (!_form.currentState!.validate()) return;
    final code = PromoCodeModel.normalize(_code.text);
    if (!_isEdit) {
      setState(() => _saving = true);
      final exists = await widget.service.promoCodeExists(code);
      if (!mounted) return;
      setState(() => _saving = false);
      if (exists) {
        setState(() => _codeError = 'This code already exists');
        return;
      }
    }
    Navigator.pop(
      context,
      PromoCodeModel(
        code: code,
        discountPercent: int.parse(_percent.text.trim()),
        isActive: _active,
        expiresAt: _expires,
        maxUses: _maxUses.text.trim().isEmpty ? null : int.parse(_maxUses.text.trim()),
        usedCount: widget.initial?.usedCount ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Promo Code' : 'Add Promo Code'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _code,
                enabled: !_isEdit,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_-]'))],
                decoration: InputDecoration(
                  labelText: 'Code',
                  hintText: 'e.g. RAMADAN20',
                  errorText: _codeError,
                  helperText: _isEdit ? 'The code itself can\'t be changed' : 'Letters, numbers, - and _ only',
                ),
                validator: (v) => (v == null || v.trim().length < 3) ? 'At least 3 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _percent,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Discount %', suffixText: '%'),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  return n == null || n < 1 || n > 99 ? 'Enter 1 to 99' : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxUses,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Usage limit (optional)',
                  helperText: _isEdit
                      ? 'Used ${widget.initial!.usedCount} time(s) so far. Leave empty for unlimited.'
                      : 'Leave empty for unlimited',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v.trim());
                  return n == null || n < 1 ? 'Enter a number greater than 0' : null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _expires == null ? 'No expiry date' : 'Expires: ${_dateFmt.format(_expires!)}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event, size: 18),
                    label: Text(_expires == null ? 'Set expiry' : 'Change'),
                  ),
                  if (_expires != null)
                    IconButton(
                      tooltip: 'Remove expiry',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _expires = null),
                    ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _saving ? null : _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
