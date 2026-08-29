import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import '../blocs/categories/categories_bloc.dart';
import '../blocs/categories/categories_event.dart';
import '../blocs/categories/categories_state.dart';
import '../config/google_config.dart';
import '../models/main_category_model.dart';
import '../models/sub_category_model.dart';
import '../services/firestore_service.dart';
import '../services/google_sheets_service.dart';
import '../services/excel_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_overlay.dart';
import '../theme/app_colors.dart';

@RoutePage()
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final ExcelService _excelService = ExcelService();
  final GoogleSheetsService _sheetsService = GoogleSheetsService();

  late TabController _tabController;
  String? _selectedMainCategoryId;
  bool _uploading = false;
  bool _importing = false;
  bool _syncing = false;
  // Prevents auto-sync to sheet while a sheet→Firestore sync is in progress
  bool _syncingFromSheet = false;

  static const int _rowsPerPage = 15;
  int _mainPage = 0;
  int _subPage = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    context.read<CategoriesBloc>().add(const LoadCategories());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) setState(() {});
  }

  bool get _isMainTab => _tabController.index == 0;

  // ── Category dialog (add / edit) ─────────────────────────────────────────

  void _showCategoryDialog(
    BuildContext context,
    List<MainCategoryModel> mainCategories, [
    dynamic category,
  ]) {
    final isEditing = category != null;

    final codeCtrl = TextEditingController(
      text: isEditing
          ? (_isMainTab
              ? (category as MainCategoryModel).code
              : (category as SubCategoryModel).code)
          : '',
    );
    final nameCtrl = TextEditingController(
      text: isEditing
          ? (_isMainTab
              ? (category as MainCategoryModel).nameAr
              : (category as SubCategoryModel).nameAr)
          : '',
    );
    final orderCtrl = TextEditingController(
      text: isEditing
          ? (_isMainTab
              ? (category as MainCategoryModel).displayOrder.toString()
              : (category as SubCategoryModel).displayOrder.toString())
          : mainCategories.length.toString(),
    );

    String? mediaUrl = isEditing && !_isMainTab
        ? (category as SubCategoryModel).mediaUrl
        : null;

    bool isActive = isEditing
        ? (_isMainTab
            ? (category as MainCategoryModel).isActive
            : (category as SubCategoryModel).isActive)
        : true;

    String? selectedMainCatId = !_isMainTab && isEditing
        ? (category as SubCategoryModel).mainCategoryId
        : (_selectedMainCategoryId ??
            (mainCategories.isNotEmpty ? mainCategories.first.id : null));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: Text(
            isEditing
                ? 'Edit ${_isMainTab ? 'Main' : 'Sub'} Category'
                : 'Add ${_isMainTab ? 'Main' : 'Sub'} Category',
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Parent dropdown (sub only)
                  if (!_isMainTab) ...[
                    const Text('Main Category *',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: mainCategories
                              .any((c) => c.id == selectedMainCatId)
                          ? selectedMainCatId
                          : (mainCategories.isNotEmpty
                              ? mainCategories.first.id
                              : null),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                      ),
                      items: mainCategories
                          .fold<Map<String, MainCategoryModel>>(
                              {},
                              (m, c) => m..putIfAbsent(c.id, () => c))
                          .values
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                    '${c.code.isNotEmpty ? '[${c.code}] ' : ''}${c.nameAr}'),
                              ))
                          .toList(),
                      onChanged: (v) => setDs(() => selectedMainCatId = v),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Code
                  CustomTextField(
                    label: _isMainTab
                        ? 'Category Code (كود الفئة) *'
                        : 'Sub-category Code (كود الصنف) *',
                    controller: codeCtrl,
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Name
                  CustomTextField(
                    label: 'Name (Arabic) *',
                    controller: nameCtrl,
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Display order
                  CustomTextField(
                    label: 'Display Order *',
                    controller: orderCtrl,
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Media — sub categories only
                  if (!_isMainTab) ...[
                    const Text('Media (Image) *',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    if (mediaUrl != null) ...[
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              mediaUrl!,
                              width: 128,
                              height: 128,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 128,
                                height: 128,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.all(4),
                              ),
                              onPressed: () =>
                                  setDs(() => mediaUrl = null),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    ElevatedButton.icon(
                      icon: _uploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : const Icon(Icons.upload),
                      label: Text(
                          _uploading ? 'Uploading…' : 'Upload Image'),
                      onPressed: _uploading
                          ? null
                          : () async {
                              final result =
                                  await FilePicker.platform.pickFiles(
                                type: FileType.image,
                                allowMultiple: false,
                              );
                              if (result != null &&
                                  result.files.isNotEmpty) {
                                setDs(() => _uploading = true);
                                try {
                                  final f = result.files.first;
                                  final url =
                                      await _firestoreService.uploadMedia(
                                    f.bytes!,
                                    f.name,
                                    'sub-categories',
                                  );
                                  setDs(() {
                                    mediaUrl = url;
                                    _uploading = false;
                                  });
                                } catch (e) {
                                  setDs(() => _uploading = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Upload failed: $e')),
                                    );
                                  }
                                }
                              }
                            },
                    ),
                    const SizedBox(height: 8),
                    Text('Required: Upload an icon/image for this sub category',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 16),
                  ],

                  // Active toggle
                  CheckboxListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (v) =>
                        setDs(() => isActive = v ?? true),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _uploading
                  ? null
                  : () {
                      if (nameCtrl.text.isEmpty || codeCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Code and Name are required')),
                        );
                        return;
                      }
                      if (!_isMainTab && mediaUrl == null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Media is required for sub categories')),
                        );
                        return;
                      }

                      final bloc = context.read<CategoriesBloc>();

                      if (_isMainTab) {
                        final data = {
                          'code': codeCtrl.text.trim().toUpperCase(),
                          'name_ar': nameCtrl.text,
                          'display_order':
                              int.tryParse(orderCtrl.text) ?? 0,
                          'is_active': isActive,
                          'status': isActive ? 'active' : 'disabled',
                        };
                        if (isEditing) {
                          bloc.add(UpdateMainCategory(
                              (category as MainCategoryModel).id, data));
                        } else {
                          bloc.add(CreateMainCategory(data));
                        }
                      } else {
                        final data = {
                          'code': codeCtrl.text.trim().toUpperCase(),
                          'main_category_id': selectedMainCatId!,
                          'name_ar': nameCtrl.text,
                          'display_order':
                              int.tryParse(orderCtrl.text) ?? 0,
                          'is_active': isActive,
                          'media_url': mediaUrl!,
                        };
                        if (isEditing) {
                          bloc.add(UpdateSubCategory(
                              (category as SubCategoryModel).id, data));
                        } else {
                          bloc.add(CreateSubCategory(data));
                        }
                      }
                      Navigator.pop(ctx);
                    },
              child: Text(isEditing ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Export (download current Google Sheet as xlsx) ───────────────────────

  void _handleExport() {
    html.window.open(kSpreadsheetExportUrl, '_blank');
  }

  // ── Template ─────────────────────────────────────────────────────────────

  void _handleTemplate() {
    _excelService.downloadTemplate(
        _isMainTab ? 'main-categories' : 'sub-categories');
  }

  // ── Import from Excel file ───────────────────────────────────────────────

  Future<void> _handleImport(
    List<MainCategoryModel> mainCats,
    List<SubCategoryModel> subCats,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    setState(() => _importing = true);

    try {
      final rows =
          await _excelService.parseExcelFile(result.files.first.bytes!);

      int created = 0, skipped = 0, errors = 0;
      final errorList = <String>[];
      // Capture bloc before async gap
      final bloc = context.read<CategoriesBloc>(); // ignore: use_build_context_synchronously

      if (_isMainTab) {
        // Expected columns: code, name_ar, display_order, is_active
        for (final row in rows) {
          try {
            final code = (row['code'] ?? row['كود الفئة'] ?? '').toString().trim().toUpperCase();
            final name = (row['name_ar'] ?? row['اسم الفئة'] ?? '').toString().trim();
            if (code.isEmpty || name.isEmpty) { skipped++; continue; }
            if (mainCats.any((c) => c.code == code)) { skipped++; continue; }

            await _firestoreService.createMainCategory({
              'code': code,
              'name_ar': name,
              'display_order': int.tryParse(row['display_order']?.toString() ?? '') ?? mainCats.length,
              'is_active': true,
              'status': 'active',
            });
            created++;
          } catch (e) {
            errors++;
            errorList.add('Row error: $e');
          }
        }
      } else {
        // Expected columns: main_category_code, code, name_ar, display_order, media_url
        for (final row in rows) {
          try {
            final mainCode = (row['main_category_code'] ?? row['كود الفئة'] ?? '').toString().trim().toUpperCase();
            final code = (row['code'] ?? row['كود الصنف'] ?? '').toString().trim().toUpperCase();
            final name = (row['name_ar'] ?? row['اسم الصنف'] ?? '').toString().trim();
            if (code.isEmpty || name.isEmpty) { skipped++; continue; }

            final mainCat = mainCats.where((c) => c.code == mainCode).firstOrNull;
            if (mainCat == null) {
              errors++;
              errorList.add('Main category not found for code: $mainCode');
              continue;
            }
            if (subCats.any((s) => s.code == code)) { skipped++; continue; }

            final mediaUrl = (row['media_url'] ?? '').toString().trim();
            if (mediaUrl.isEmpty) {
              errors++;
              errorList.add('Media required for: $name');
              continue;
            }

            await _firestoreService.createSubCategory({
              'code': code,
              'main_category_id': mainCat.id,
              'name_ar': name,
              'display_order': int.tryParse(row['display_order']?.toString() ?? '') ?? 0,
              'is_active': true,
              'media_url': mediaUrl,
            });
            created++;
          } catch (e) {
            errors++;
            errorList.add('Row error: $e');
          }
        }
      }

      bloc.add(const LoadCategories());

      // Sync updated categories back to Google Sheet
      await _syncToSheet();

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Import Complete'),
            content: Text(
              'Created: $created\nSkipped (duplicates): $skipped\nErrors: $errors'
              '${errorList.isNotEmpty ? '\n\nErrors:\n${errorList.take(5).join('\n')}' : ''}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  // ── Sync Now: Google Sheet → Firestore ───────────────────────────────────

  Future<void> _syncFromSheet() async {
    _syncingFromSheet = true;
    setState(() => _syncing = true);
    try {
      final result = await _sheetsService.syncFromSheetToFirestore(
          _firestoreService);

      // Reload bloc after Firestore was updated
      if (mounted) {
        context.read<CategoriesBloc>().add(const LoadCategories());
        final total = result.mainCreated + result.mainUpdated +
            result.subCreated + result.subUpdated + result.skipped;
        final msg = total == 0
            ? 'No rows found in sheet — check sheet name and sharing'
            : 'Synced from Sheet — '
              'Main: +${result.mainCreated} created, ${result.mainUpdated} updated · '
              'Sub: +${result.subCreated} created, ${result.subUpdated} updated · '
              '${result.skipped} unchanged';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: total == 0 ? AppColors.warning : AppColors.success,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      _syncingFromSheet = false;
      if (mounted) setState(() => _syncing = false);
    }
  }

  // ── After dashboard edit: push Firestore → Google Sheet ──────────────────

  Future<void> _syncToSheet() async {
    try {
      final mainCats = await _firestoreService.getMainCategories();
      final subCats = await _firestoreService.getSubCategories();
      await _sheetsService.syncCategoriesToSheet(mainCats, subCats);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sheet sync failed: $e'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) =>
      DateFormat('MMM dd, yyyy').format(date);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CategoriesBloc, CategoriesState>(
      listener: (context, state) {
        if (state is CategoriesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.danger),
          );
        } else if (state is CategoryOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.secondary),
          );
          // shouldSync is false for delete operations to avoid overwriting sheet edits
          if (state.shouldSync && !_syncingFromSheet) _syncToSheet();
        } else if (state is CategoriesLoaded) {
          // Also sync after reload (e.g., after import)
          // Avoid sync loops: only sync if triggered externally
        }
      },
      builder: (context, state) {
        List<MainCategoryModel> mainCats = [];
        List<SubCategoryModel> subCats = [];
        final isLoading = state is CategoriesLoading;

        if (state is CategoriesLoaded) {
          mainCats = state.mainCategories;
          subCats = state.subCategories;
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: LoadingOverlay(
            isLoading: isLoading || _importing || _syncing,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ──────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Categories',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text(
                                'Synced with Google Sheets',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary),
                              ),
                              if (_syncing) ...[
                                const SizedBox(width: 8),
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      // Action buttons
                      Wrap(
                        spacing: 10,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.download_outlined,
                                size: 16),
                            label: const Text('Template'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                            ),
                            onPressed: _handleTemplate,
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.table_chart_outlined,
                                size: 16),
                            label: const Text('Export Sheet'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(
                                  color: AppColors.primary),
                            ),
                            onPressed: _handleExport,
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.sync_rounded, size: 16),
                            label: const Text('Sync Now'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.success,
                              side: const BorderSide(
                                  color: AppColors.success),
                            ),
                            onPressed: _syncing ? null : _syncFromSheet,
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.upload, size: 16),
                            label: const Text('Import Excel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () =>
                                _handleImport(mainCats, subCats),
                          ),
                          CustomButton(
                            text: _isMainTab
                                ? 'Add Main Category'
                                : 'Add Sub Category',
                            icon: Icons.add,
                            onPressed: () =>
                                _showCategoryDialog(context, mainCats),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Tabs + table ────────────────────────────────────────
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          TabBar(
                            controller: _tabController,
                            labelColor: AppColors.primary,
                            unselectedLabelColor: AppColors.textLight,
                            indicatorColor: AppColors.primary,
                            onTap: (_) => setState(() {}),
                            tabs: [
                              Tab(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.folder),
                                    const SizedBox(width: 8),
                                    Text(
                                        'Main Categories (${mainCats.length})'),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.folder_open),
                                    const SizedBox(width: 8),
                                    Text(
                                        'Sub Categories (${subCats.length})'),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Sub category filter
                          if (!_isMainTab)
                            Container(
                              padding: const EdgeInsets.all(16),
                              color: Colors.grey[50],
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Filter by Main Category',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String?>(
                                    value: (_selectedMainCategoryId !=
                                                null &&
                                            mainCats.any((c) =>
                                                c.id ==
                                                _selectedMainCategoryId))
                                        ? _selectedMainCategoryId
                                        : null,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding:
                                          EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12),
                                    ),
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child:
                                            Text('All Main Categories'),
                                      ),
                                      ...mainCats
                                          .where((c) => c.isActive)
                                          .fold<
                                              Map<String,
                                                  MainCategoryModel>>(
                                            {},
                                            (m, c) => m
                                              ..putIfAbsent(c.id, () => c),
                                          )
                                          .values
                                          .map((c) =>
                                              DropdownMenuItem<String?>(
                                                value: c.id,
                                                child: Text(
                                                    '${c.code.isNotEmpty ? '[${c.code}] ' : ''}${c.nameAr}'),
                                              )),
                                    ],
                                    onChanged: (v) {
                                      setState(() =>
                                          _selectedMainCategoryId = v);
                                      context
                                          .read<CategoriesBloc>()
                                          .add(LoadCategories(
                                              selectedMainCategoryId: v));
                                    },
                                  ),
                                ],
                              ),
                            ),

                          // Data table + pagination
                          Expanded(
                            child: Builder(builder: (ctx) {
                              if (_isMainTab) {
                                final totalPages = (mainCats.length / _rowsPerPage).ceil().clamp(1, 999999);
                                final page = _mainPage.clamp(0, totalPages - 1);
                                final paginated = mainCats.skip(page * _rowsPerPage).take(_rowsPerPage).toList();
                                return Column(children: [
                                  Expanded(
                                    child: LayoutBuilder(
                                      builder: (ctx2, constraints) => Scrollbar(
                                        thumbVisibility: true,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.vertical,
                                              child: _mainCatTable(paginated, mainCats, context),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  _paginationBar(mainCats.length, page, totalPages,
                                    (p) => setState(() => _mainPage = p)),
                                ]);
                              } else {
                                final totalPages = (subCats.length / _rowsPerPage).ceil().clamp(1, 999999);
                                final page = _subPage.clamp(0, totalPages - 1);
                                final paginated = subCats.skip(page * _rowsPerPage).take(_rowsPerPage).toList();
                                return Column(children: [
                                  Expanded(
                                    child: LayoutBuilder(
                                      builder: (ctx2, constraints) => Scrollbar(
                                        thumbVisibility: true,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.vertical,
                                              child: _subCatTable(paginated, mainCats, context),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  _paginationBar(subCats.length, page, totalPages,
                                    (p) => setState(() => _subPage = p)),
                                ]);
                              }
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Pagination bar ────────────────────────────────────────────────────────

  Widget _paginationBar(int total, int page, int totalPages, void Function(int) onPage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        color: Colors.grey[50],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${total == 0 ? 0 : page * _rowsPerPage + 1}–${(page * _rowsPerPage + _rowsPerPage).clamp(0, total)} of $total',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          Row(children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: page > 0 ? () => onPage(page - 1) : null,
              tooltip: 'Previous',
              iconSize: 20,
            ),
            ...List.generate(totalPages, (i) => i)
                .where((i) => (i - page).abs() <= 2)
                .map((i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(36, 36),
                          padding: EdgeInsets.zero,
                          backgroundColor: i == page ? AppColors.primary : null,
                          foregroundColor: i == page ? Colors.white : null,
                        ),
                        onPressed: i == page ? null : () => onPage(i),
                        child: Text('${i + 1}', style: const TextStyle(fontSize: 13)),
                      ),
                    )),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: page < totalPages - 1 ? () => onPage(page + 1) : null,
              tooltip: 'Next',
              iconSize: 20,
            ),
          ]),
        ],
      ),
    );
  }

  // ── Main categories DataTable ─────────────────────────────────────────────

  Widget _mainCatTable(
      List<MainCategoryModel> cats, List<MainCategoryModel> allCats, BuildContext context) {
    final headStyle =
        const TextStyle(fontWeight: FontWeight.w600);

    return DataTable(
      headingRowColor:
          WidgetStateProperty.all(Colors.grey[50]),
      columnSpacing: 24,
      horizontalMargin: 16,
      columns: [
        DataColumn(label: Text('Order', style: headStyle)),
        DataColumn(label: Text('Code', style: headStyle)),
        DataColumn(label: Text('Name (Arabic)', style: headStyle)),
        DataColumn(label: Text('Status', style: headStyle)),
        DataColumn(label: Text('Created At', style: headStyle)),
        DataColumn(label: Text('Actions', style: headStyle)),
      ],
      rows: cats.isEmpty
          ? [
              const DataRow(cells: [
                DataCell(SizedBox()),
                DataCell(Text('No main categories found')),
                DataCell(SizedBox()),
                DataCell(SizedBox()),
                DataCell(SizedBox()),
                DataCell(SizedBox()),
              ])
            ]
          : cats
              .map((c) => DataRow(cells: [
                    DataCell(Text(c.displayOrder.toString())),
                    DataCell(_codeChip(c.code)),
                    DataCell(Text(c.nameAr,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500))),
                    DataCell(_statusBadge(c.isActive)),
                    DataCell(Text(_formatDate(c.createdAt))),
                    DataCell(Row(children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        color: AppColors.primary,
                        onPressed: () =>
                            _showCategoryDialog(context, allCats, c),
                      ),
                      IconButton(
                        icon: const Icon(Icons.power_settings_new,
                            size: 18),
                        color: c.isActive
                            ? AppColors.danger
                            : AppColors.secondary,
                        onPressed: () {
                          context.read<CategoriesBloc>().add(
                              ToggleMainCategoryStatus(
                                  c.id, !c.isActive));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: AppColors.danger,
                        onPressed: () => _confirmDelete(
                          context,
                          label: c.nameAr,
                          onConfirm: () => context
                              .read<CategoriesBloc>()
                              .add(DeleteMainCategory(c.id)),
                        ),
                      ),
                    ])),
                  ]))
              .toList(),
    );
  }

  // ── Sub categories DataTable ──────────────────────────────────────────────

  Widget _subCatTable(
    List<SubCategoryModel> cats,
    List<MainCategoryModel> mainCats,
    BuildContext context,
  ) {
    final headStyle =
        const TextStyle(fontWeight: FontWeight.w600);

    return DataTable(
      headingRowColor:
          WidgetStateProperty.all(Colors.grey[50]),
      columnSpacing: 24,
      horizontalMargin: 16,
      columns: [
        DataColumn(label: Text('Order', style: headStyle)),
        DataColumn(label: Text('Code', style: headStyle)),
        DataColumn(label: Text('Name (Arabic)', style: headStyle)),
        DataColumn(label: Text('Description', style: headStyle)),
        DataColumn(label: Text('Main Category', style: headStyle)),
        DataColumn(label: Text('Media', style: headStyle)),
        DataColumn(label: Text('Status', style: headStyle)),
        DataColumn(label: Text('Created At', style: headStyle)),
        DataColumn(label: Text('Actions', style: headStyle)),
      ],
      rows: cats.isEmpty
          ? [
              const DataRow(cells: [
                DataCell(SizedBox()),
                DataCell(Text('No sub categories found')),
                DataCell(SizedBox()),
                DataCell(SizedBox()),
                DataCell(SizedBox()),
                DataCell(SizedBox()),
                DataCell(SizedBox()),
                DataCell(SizedBox()),
                DataCell(SizedBox()),
              ])
            ]
          : cats
              .map((c) => DataRow(cells: [
                    DataCell(Text(c.displayOrder.toString())),
                    DataCell(_codeChip(c.code)),
                    DataCell(Text(c.nameAr,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500))),
                    DataCell(SizedBox(
                      width: 200,
                      child: Text(c.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    )),
                    DataCell(Text(mainCats
                            .where((m) => m.id == c.mainCategoryId)
                            .firstOrNull
                            ?.nameAr ??
                        'N/A')),
                    DataCell(ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: c.mediaUrl.isEmpty
                          ? Container(
                              width: 48,
                              height: 48,
                              color: Colors.grey[200],
                              child: Icon(Icons.image, color: Colors.grey[400]),
                            )
                          : Image.network(
                              _driveImageUrl(c.mediaUrl),
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 48,
                                height: 48,
                                color: Colors.grey[200],
                                child: Icon(Icons.image,
                                    color: Colors.grey[400]),
                              ),
                            ),
                    )),
                    DataCell(_statusBadge(c.isActive)),
                    DataCell(Text(_formatDate(c.createdAt))),
                    DataCell(Row(children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        color: AppColors.primary,
                        onPressed: () =>
                            _showCategoryDialog(context, mainCats, c),
                      ),
                      IconButton(
                        icon: const Icon(Icons.power_settings_new,
                            size: 18),
                        color: c.isActive
                            ? AppColors.danger
                            : AppColors.secondary,
                        onPressed: () => context
                            .read<CategoriesBloc>()
                            .add(ToggleSubCategoryStatus(
                                c.id, !c.isActive)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: AppColors.danger,
                        onPressed: () => _confirmDelete(
                          context,
                          label: c.nameAr,
                          onConfirm: () => context
                              .read<CategoriesBloc>()
                              .add(DeleteSubCategory(c.id)),
                        ),
                      ),
                    ])),
                  ]))
              .toList(),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  /// Converts a Google Drive sharing link to a thumbnail URL that can be
  /// loaded by Image.network in Flutter web.
  /// Input:  https://drive.google.com/file/d/FILE_ID/view?usp=sharing
  /// Output: https://lh3.googleusercontent.com/d/FILE_ID
  String _driveImageUrl(String url) {
    if (url.isEmpty) return url;
    if (url.contains('drive.google.com/file/d/')) {
      final start = url.indexOf('/file/d/') + 8;
      var end = url.indexOf('/', start);
      if (end < 0) end = url.length;
      final fileId = url.substring(start, end);
      return 'https://lh3.googleusercontent.com/d/$fileId';
    }
    if (url.contains('drive.google.com/open?id=') ||
        url.contains('drive.google.com/uc?')) {
      final idStart = url.indexOf('id=') + 3;
      var idEnd = url.indexOf('&', idStart);
      if (idEnd < 0) idEnd = url.length;
      final fileId = url.substring(idStart, idEnd);
      return 'https://lh3.googleusercontent.com/d/$fileId';
    }
    return url;
  }

  void _confirmDelete(
    BuildContext context, {
    required String label,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete "$label"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _codeChip(String code) {
    if (code.isEmpty) return const Text('—');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        code,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _statusBadge(bool isActive) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? AppColors.successLight : AppColors.dangerLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Active' : 'Disabled',
        style: TextStyle(
          color: isActive ? AppColors.success : AppColors.dangerDark,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
