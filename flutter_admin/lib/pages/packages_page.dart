import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_package_model.dart';
import '../services/store_service.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_data_table.dart';
import '../widgets/empty_state.dart';

const _swatches = ['#D64453', '#9C27B0', '#4CAF50', '#E91E63', '#2196F3', '#FF9800', '#600522', '#009688'];

Color _hex(String hex) => Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));

String _formatPrice(double p) => p == p.roundToDouble() ? p.toInt().toString() : p.toStringAsFixed(2);

@RoutePage()
class PackagesPage extends StatefulWidget {
  const PackagesPage({super.key});

  @override
  State<PackagesPage> createState() => _PackagesPageState();
}

class _PackagesPageState extends State<PackagesPage> {
  final _service = StoreService();

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.success,
    ));
  }

  Future<void> _openEditor(List<GamePackageModel> all, [GamePackageModel? pkg]) async {
    final saved = await showDialog<GamePackageModel>(
      context: context,
      builder: (_) => _PackageDialog(
        initial: pkg,
        nextOrder: all.isEmpty ? 1 : all.map((p) => p.displayOrder).reduce((a, b) => a > b ? a : b) + 1,
      ),
    );
    if (saved == null) return;
    try {
      await _service.savePackage(saved);
      _snack(pkg == null ? 'Package created' : 'Package updated');
    } catch (e) {
      _snack('Save failed: $e', error: true);
    }
  }

  Future<void> _delete(GamePackageModel pkg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete package'),
        content: Text('Delete "${pkg.titleAr}"? Customers will no longer see it in the app.'),
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
      await _service.deletePackage(pkg.id);
      _snack('Package deleted');
    } catch (e) {
      _snack('Delete failed: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<GamePackageModel>>(
        stream: _service.watchPackages(),
        builder: (context, snap) {
          final packages = snap.data ?? [];
          return Padding(
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
                          Text('Packages',
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          SizedBox(height: 4),
                          Text('Game packages customers can buy. Changes appear in the app immediately.',
                              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    CustomButton(text: 'Add Package', icon: Icons.add, onPressed: () => _openEditor(packages)),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(child: _buildBody(snap, packages)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(AsyncSnapshot<List<GamePackageModel>> snap, List<GamePackageModel> packages) {
    if (snap.hasError) {
      return Center(child: Text('Error: ${snap.error}', style: const TextStyle(color: AppColors.danger)));
    }
    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
    if (packages.isEmpty) {
      return const EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No packages',
        message: 'Customers won\'t be able to buy games until you add a package.',
      );
    }
    return CustomDataTable(
      columns: const ['Order', 'Title', 'Games', 'Price (SAR)', 'Color', 'Status'],
      rows: packages
          .map((p) => [
                '${p.displayOrder}',
                p.titleAr,
                '${p.gamesCount}',
                _formatPrice(p.priceSar),
                p.color,
                p.isActive ? 'Active' : 'Hidden',
              ])
          .toList(),
      onEdit: (i) => _openEditor(packages, packages[i]),
      onDelete: (i) => _delete(packages[i]),
    );
  }
}

class _PackageDialog extends StatefulWidget {
  final GamePackageModel? initial;
  final int nextOrder;

  const _PackageDialog({this.initial, required this.nextOrder});

  @override
  State<_PackageDialog> createState() => _PackageDialogState();
}

class _PackageDialogState extends State<_PackageDialog> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.titleAr ?? '');
  late final _games = TextEditingController(text: widget.initial?.gamesCount.toString() ?? '');
  late final _price = TextEditingController(
      text: widget.initial == null ? '' : _formatPrice(widget.initial!.priceSar));
  late final _order = TextEditingController(
      text: (widget.initial?.displayOrder ?? widget.nextOrder).toString());
  late String _color = widget.initial?.color ?? _swatches.first;
  late bool _active = widget.initial?.isActive ?? true;

  @override
  void initState() {
    super.initState();
    for (final c in [_title, _price]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _games, _price, _order]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _positiveInt(String? v) {
    final n = int.tryParse(v?.trim() ?? '');
    return n == null || n <= 0 ? 'Enter a whole number greater than 0' : null;
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(
      context,
      GamePackageModel(
        id: widget.initial?.id ?? '',
        titleAr: _title.text.trim(),
        gamesCount: int.parse(_games.text.trim()),
        priceSar: double.parse(_price.text.trim()),
        color: _color,
        isActive: _active,
        displayOrder: int.parse(_order.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(_price.text.trim());
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add Package' : 'Edit Package'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _title,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(labelText: 'Title (Arabic)', hintText: 'مثال: 5 ألعاب'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _games,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(labelText: 'Number of games'),
                        validator: _positiveInt,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                        decoration: const InputDecoration(labelText: 'Price (SAR)'),
                        validator: (v) {
                          final p = double.tryParse(v?.trim() ?? '');
                          // Moyasar's minimum charge is 1 SAR.
                          return p == null || p < 1 ? 'Minimum price is 1 SAR' : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _order,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Display order (1 = top)'),
                  validator: _positiveInt,
                ),
                const SizedBox(height: 16),
                const Text('Button color', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _swatches
                      .map((hex) => InkWell(
                            onTap: () => setState(() => _color = hex),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: _hex(hex),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _color == hex ? AppColors.textPrimary : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Visible in app'),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
                const SizedBox(height: 8),
                const Text('Preview', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(color: _hex(_color), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('SAR ${price == null ? '—' : _formatPrice(price)}',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(_title.text.isEmpty ? '—' : _title.text,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
