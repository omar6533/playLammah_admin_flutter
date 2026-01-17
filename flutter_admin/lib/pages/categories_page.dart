import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/categories/categories_bloc.dart';
import '../blocs/categories/categories_event.dart';
import '../blocs/categories/categories_state.dart';
import '../models/main_category_model.dart';
import '../models/sub_category_model.dart';
import '../services/firestore_service.dart';
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
  // We keep FirestoreService locally only for media upload helper that isn't in Bloc yet
  // Ideally this should move to a separate MediaBloc or similar
  final FirestoreService _firestoreService = FirestoreService();
  final ExcelService _excelService = ExcelService();

  late TabController _tabController;
  String? _selectedMainCategoryId;
  bool _uploading = false;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Initial Load
    context.read<CategoriesBloc>().add(const LoadCategories());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  void _showCategoryDialog(
      BuildContext context, List<MainCategoryModel> mainCategories,
      [dynamic category]) {
    final isMainTab = _tabController.index == 0;
    final isEditing = category != null;

    final nameController = TextEditingController(
      text: isEditing
          ? (isMainTab
              ? (category as MainCategoryModel).nameAr
              : (category as SubCategoryModel).nameAr)
          : '',
    );
    final displayOrderController = TextEditingController(
      text: isEditing
          ? (isMainTab
              ? (category as MainCategoryModel).displayOrder.toString()
              : (category as SubCategoryModel).displayOrder.toString())
          : (isMainTab
              ? mainCategories.length.toString()
              : '0'), // Approximation for sub categories
    );

    String? mediaUrl = isEditing
        ? (isMainTab
            ? (category as MainCategoryModel).mediaUrl
            : (category as SubCategoryModel).mediaUrl)
        : null;

    bool isActive = isEditing
        ? (isMainTab
            ? (category as MainCategoryModel).isActive
            : (category as SubCategoryModel).isActive)
        : true;

    String? selectedMainCatId = !isMainTab && isEditing
        ? (category as SubCategoryModel).mainCategoryId
        : (_selectedMainCategoryId ??
            (mainCategories.isNotEmpty ? mainCategories.first.id : null));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isEditing
                ? 'Edit ${isMainTab ? 'Main' : 'Sub'} Category'
                : 'Add ${isMainTab ? 'Main' : 'Sub'} Category',
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMainTab) ...[
                    const Text(
                      'Main Category *',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMainCatId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      items: mainCategories.map((cat) {
                        return DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.nameAr),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedMainCatId = value);
                      },
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  CustomTextField(
                    label: 'Name (Arabic) *',
                    controller: nameController,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Display Order *',
                    controller: displayOrderController,
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Media (Image) ${!isMainTab ? '*' : ''}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  if (mediaUrl != null) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            mediaUrl ?? '',
                            width: 128,
                            height: 128,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
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
                            icon: const Icon(Icons.close, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.all(4),
                            ),
                            onPressed: () =>
                                setDialogState(() => mediaUrl = null),
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
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.upload),
                    label: Text(_uploading ? 'Uploading...' : 'Upload Image'),
                    onPressed: _uploading
                        ? null
                        : () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                              allowMultiple: false,
                            );

                            if (result != null && result.files.isNotEmpty) {
                              setDialogState(() => _uploading = true);
                              try {
                                final file = result.files.first;
                                final bucket = isMainTab
                                    ? 'main-categories'
                                    : 'sub-categories';
                                // We use local service for upload, as this is transient
                                final url = await _firestoreService.uploadMedia(
                                  file.bytes!,
                                  file.name,
                                  bucket,
                                );
                                setDialogState(() {
                                  mediaUrl = url;
                                  _uploading = false;
                                });
                              } catch (e) {
                                setDialogState(() => _uploading = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Upload failed: $e')),
                                  );
                                }
                              }
                            }
                          },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isMainTab
                        ? 'Optional: Upload a banner image for this main category'
                        : 'Required: Upload an icon/image for this sub category',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (value) =>
                        setDialogState(() => isActive = value ?? true),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _uploading
                  ? null
                  : () {
                      if (nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Name is required')),
                        );
                        return;
                      }

                      if (!isMainTab && mediaUrl == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Media is required for sub categories')),
                        );
                        return;
                      }

                      final bloc = context.read<CategoriesBloc>();

                      if (isMainTab) {
                        final data = {
                          'name_ar': nameController.text,
                          'display_order':
                              int.parse(displayOrderController.text),
                          'is_active': isActive,
                          'status': isActive ? 'active' : 'disabled',
                          'media_url': mediaUrl,
                        };

                        if (isEditing) {
                          bloc.add(UpdateMainCategory(
                            (category as MainCategoryModel).id,
                            data,
                          ));
                        } else {
                          bloc.add(CreateMainCategory(data));
                        }
                      } else {
                        final data = {
                          'main_category_id': selectedMainCatId!,
                          'name_ar': nameController.text,
                          'display_order':
                              int.parse(displayOrderController.text),
                          'is_active': isActive,
                          'media_url': mediaUrl!,
                        };

                        if (isEditing) {
                          bloc.add(UpdateSubCategory(
                            (category as SubCategoryModel).id,
                            data,
                          ));
                        } else {
                          bloc.add(CreateSubCategory(data));
                        }
                      }
                      Navigator.pop(context);
                    },
              child: Text(isEditing ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleExport(
      List<MainCategoryModel> mainCats, List<SubCategoryModel> subCats) {
    final isMainTab = _tabController.index == 0;
    if (isMainTab) {
      _excelService.exportMainCategories(mainCats);
    } else {
      _excelService.exportSubCategories(subCats);
    }
  }

  // Keeping Import logic locally for now, could be moved to Bloc later
  Future<void> _handleImport(
      List<MainCategoryModel> mainCats, List<SubCategoryModel> subCats) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() => _importing = true);

    try {
      final isMainTab = _tabController.index == 0;
      final rows =
          await _excelService.parseExcelFile(result.files.first.bytes!);

      int successCount = 0;
      int errorCount = 0;
      int skippedCount = 0;
      List<String> errors = [];

      final bloc = context.read<CategoriesBloc>();

      for (final row in rows) {
        try {
          if (isMainTab) {
            final existing =
                mainCats.any((cat) => cat.nameAr == row['name_ar']);
            if (existing) {
              skippedCount++;
              continue;
            }

            // Directly using service here to avoid flooding Bloc events one by one without batch
            await _firestoreService.createMainCategory({
              'name_ar': row['name_ar'],
              'display_order': row['display_order'] ?? mainCats.length,
              'is_active':
                  row['is_active'] == 'true' || row['is_active'] == true,
              'status': (row['is_active'] == 'true' || row['is_active'] == true)
                  ? 'active'
                  : 'disabled',
              'media_url': row['media_url'],
            });
            successCount++;
          } else {
            // Logic for subcategories...
            final mainCatName = row['main_category_name_ar'];
            // We need to find mainCatId. We can use the passed list.
            final mainCat =
                mainCats.where((cat) => cat.nameAr == mainCatName).firstOrNull;

            if (mainCat == null) {
              errors.add('Main category not found for: ${row['name_ar']}');
              errorCount++;
              continue;
            }

            final existing = subCats.any(
              (cat) =>
                  cat.mainCategoryId == mainCat.id &&
                  cat.nameAr == row['name_ar'],
            );

            if (existing) {
              skippedCount++;
              continue;
            }

            if (row['media_url'] == null ||
                row['media_url'].toString().isEmpty) {
              errors.add('Media required for: ${row['name_ar']}');
              errorCount++;
              continue;
            }

            await _firestoreService.createSubCategory({
              'main_category_id': mainCat.id,
              'name_ar': row['name_ar'],
              'display_order': row['display_order'] ?? 0,
              'is_active':
                  row['is_active'] == 'true' || row['is_active'] == true,
              'media_url': row['media_url'],
            });
            successCount++;
          }
        } catch (e) {
          errors.add('Row error: $e');
          errorCount++;
        }
      }

      // Reload everything after import
      bloc.add(const LoadCategories());

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import Complete'),
            content: Text(
              'Created: $successCount\nSkipped: $skippedCount\nErrors: $errorCount'
              '${errors.isNotEmpty ? '\n\nErrors:\n${errors.take(5).join('\n')}' : ''}',
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
      setState(() => _importing = false);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isMainTab = _tabController.index == 0;

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
        }
      },
      builder: (context, state) {
        List<MainCategoryModel> mainCats = [];
        List<SubCategoryModel> subCats = [];
        bool isLoading = state is CategoriesLoading;

        if (state is CategoriesLoaded) {
          mainCats = state.mainCategories;
          subCats = state.subCategories;
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: LoadingOverlay(
            isLoading: isLoading || _importing,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          const Text(
                            'Manage main categories and sub categories for SeenJeem board',
                            style: TextStyle(
                                fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      // Buttons
                      Row(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text('Template'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: Colors.grey[700],
                            ),
                            onPressed: () {
                              _excelService.downloadTemplate(isMainTab
                                  ? 'main-categories'
                                  : 'sub-categories');
                            },
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text('Export'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: Colors.grey[700],
                            ),
                            onPressed: () => _handleExport(mainCats, subCats),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.upload, size: 18),
                            label: const Text('Import'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _handleImport(mainCats, subCats),
                          ),
                          const SizedBox(width: 12),
                          CustomButton(
                            text:
                                'Add ${isMainTab ? 'Main Category' : 'Sub Category'}',
                            icon: Icons.add,
                            onPressed: () =>
                                _showCategoryDialog(context, mainCats),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                            onTap: (index) {
                              setState(() {}); // Rebuild to Switch logic
                            },
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
                                    Text('Sub Categories (${subCats.length})'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (!isMainTab) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              color: Colors.grey[50],
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Filter by Main Category',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String?>(
                                    initialValue: _selectedMainCategoryId,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 12),
                                    ),
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('All Main Categories'),
                                      ),
                                      ...mainCats.map((cat) {
                                        return DropdownMenuItem<String?>(
                                          value: cat.id,
                                          child: Text(cat.nameAr),
                                        );
                                      }),
                                    ],
                                    onChanged: (value) {
                                      setState(() =>
                                          _selectedMainCategoryId = value);
                                      context.read<CategoriesBloc>().add(
                                          LoadCategories(
                                              selectedMainCategoryId: value));
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                          // Data Table
                          Expanded(
                              child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SingleChildScrollView(
                                      child: DataTable(
                                          headingRowColor:
                                              WidgetStateProperty.all(
                                                  Colors.grey[50]),
                                          columns: [
                                            const DataColumn(
                                                label: Text('Order',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600))),
                                            const DataColumn(
                                                label: Text('Name (Arabic)',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600))),
                                            if (!isMainTab)
                                              const DataColumn(
                                                  label: Text('Main Category',
                                                      style: TextStyle(
                                                          fontWeight: FontWeight
                                                              .w600))),
                                            const DataColumn(
                                                label: Text('Media',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600))),
                                            const DataColumn(
                                                label: Text('Status',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600))),
                                            const DataColumn(
                                                label: Text('Created At',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600))),
                                            const DataColumn(
                                                label: Text('Actions',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600))),
                                          ],
                                          rows: isMainTab
                                              ? mainCats
                                                  .map((category) =>
                                                      DataRow(cells: [
                                                        DataCell(Text(category
                                                            .displayOrder
                                                            .toString())),
                                                        DataCell(Text(
                                                            category.nameAr,
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500))),
                                                        DataCell(category.mediaUrl != null
                                                            ? ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                        4),
                                                                child: Image.network(category.mediaUrl!,
                                                                    width: 48,
                                                                    height: 48,
                                                                    fit: BoxFit
                                                                        .cover))
                                                            : Container(
                                                                width: 48,
                                                                height: 48,
                                                                decoration: BoxDecoration(
                                                                    color:
                                                                        Colors.grey[
                                                                            200],
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            4)),
                                                                child: Icon(
                                                                    Icons.image,
                                                                    color: Colors
                                                                        .grey[400]))),
                                                        DataCell(Container(
                                                            padding: const EdgeInsets.symmetric(
                                                                horizontal: 12,
                                                                vertical: 6),
                                                            decoration: BoxDecoration(
                                                                color: category.isActive
                                                                    ? AppColors
                                                                        .secondaryLight
                                                                    : AppColors
                                                                        .dangerLight,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                        12)),
                                                            child: Text(
                                                                category.isActive
                                                                    ? 'Active'
                                                                    : 'Disabled',
                                                                style: TextStyle(
                                                                    color: category.isActive
                                                                        ? AppColors
                                                                            .secondaryDark
                                                                        : AppColors
                                                                            .dangerDark,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    fontSize: 12)))),
                                                        DataCell(Text(
                                                            _formatDate(category
                                                                .createdAt))),
                                                        DataCell(Row(children: [
                                                          IconButton(
                                                              icon: const Icon(
                                                                  Icons.edit,
                                                                  size: 18),
                                                              color: AppColors
                                                                  .primary,
                                                              onPressed: () =>
                                                                  _showCategoryDialog(
                                                                      context,
                                                                      mainCats,
                                                                      category)),
                                                          IconButton(
                                                              icon: const Icon(
                                                                  Icons
                                                                      .power_settings_new,
                                                                  size: 18),
                                                              color: category
                                                                      .isActive
                                                                  ? AppColors
                                                                      .danger
                                                                  : AppColors
                                                                      .secondary,
                                                              onPressed: () => context
                                                                  .read<
                                                                      CategoriesBloc>()
                                                                  .add(ToggleMainCategoryStatus(
                                                                      category
                                                                          .id,
                                                                      !category
                                                                          .isActive))),
                                                        ])),
                                                      ]))
                                                  .toList()
                                              : subCats
                                                  .map((category) =>
                                                      DataRow(cells: [
                                                        DataCell(Text(category
                                                            .displayOrder
                                                            .toString())),
                                                        DataCell(Text(
                                                            category.nameAr,
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500))),
                                                        DataCell(Text(mainCats
                                                                .where((m) =>
                                                                    m.id ==
                                                                    category
                                                                        .mainCategoryId)
                                                                .firstOrNull
                                                                ?.nameAr ??
                                                            'N/A')),
                                                        DataCell(ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4),
                                                            child: Image.network(
                                                                category
                                                                    .mediaUrl,
                                                                width: 48,
                                                                height: 48,
                                                                fit: BoxFit
                                                                    .cover))),
                                                        DataCell(Container(
                                                            padding: const EdgeInsets.symmetric(
                                                                horizontal: 12,
                                                                vertical: 6),
                                                            decoration: BoxDecoration(
                                                                color: category.isActive
                                                                    ? AppColors
                                                                        .secondaryLight
                                                                    : AppColors
                                                                        .dangerLight,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                        12)),
                                                            child: Text(
                                                                category.isActive
                                                                    ? 'Active'
                                                                    : 'Disabled',
                                                                style: TextStyle(
                                                                    color: category.isActive
                                                                        ? AppColors
                                                                            .secondaryDark
                                                                        : AppColors
                                                                            .dangerDark,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    fontSize: 12)))),
                                                        DataCell(Text(
                                                            _formatDate(category
                                                                .createdAt))),
                                                        DataCell(Row(children: [
                                                          IconButton(
                                                              icon: const Icon(
                                                                  Icons.edit,
                                                                  size: 18),
                                                              color: AppColors
                                                                  .primary,
                                                              onPressed: () =>
                                                                  _showCategoryDialog(
                                                                      context,
                                                                      mainCats,
                                                                      category)),
                                                          IconButton(
                                                              icon: const Icon(
                                                                  Icons
                                                                      .power_settings_new,
                                                                  size: 18),
                                                              color: category
                                                                      .isActive
                                                                  ? AppColors
                                                                      .danger
                                                                  : AppColors
                                                                      .secondary,
                                                              onPressed: () => context
                                                                  .read<
                                                                      CategoriesBloc>()
                                                                  .add(ToggleSubCategoryStatus(
                                                                      category
                                                                          .id,
                                                                      !category
                                                                          .isActive))),
                                                        ])),
                                                      ]))
                                                  .toList())))),
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
}
