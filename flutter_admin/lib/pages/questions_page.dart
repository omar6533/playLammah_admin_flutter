import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/categories/categories_bloc.dart';
import '../blocs/categories/categories_event.dart';
import '../blocs/categories/categories_state.dart';
import '../blocs/questions/questions_bloc.dart';
import '../blocs/questions/questions_event.dart';
import '../blocs/questions/questions_state.dart';
import '../models/seenjeem_question_model.dart';
import '../models/main_category_model.dart';
import '../models/sub_category_model.dart';
import '../services/firestore_service.dart';
import '../services/excel_service.dart';
import '../services/google_sheets_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_overlay.dart';
import '../theme/app_colors.dart';

@RoutePage()
class QuestionsPage extends StatefulWidget {
  const QuestionsPage({super.key});

  @override
  State<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage> {
  // Keeping services for media upload and excel export/import
  final FirestoreService _firestoreService = FirestoreService();
  final ExcelService _excelService = ExcelService();
  final GoogleSheetsService _sheetsService = GoogleSheetsService();

  String? _filterMainCategoryId;
  String? _filterSubCategoryId;
  int? _filterPoints;
  String? _filterStatus;
  String _searchQuery = '';
  int _currentPage = 0;
  static const int _pageSize = 50;

  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _verticalScrollCtrl = ScrollController();
  final ScrollController _horizScrollCtrl = ScrollController();

  bool _uploading = false;
  bool _importing = false;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    // Load categories so subcategory data is available for sync and filters
    final catState = context.read<CategoriesBloc>().state;
    if (catState is! CategoriesLoaded) {
      context.read<CategoriesBloc>().add(LoadCategories());
    }
    _loadQuestions();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _verticalScrollCtrl.dispose();
    _horizScrollCtrl.dispose();
    super.dispose();
  }

  void _loadQuestions() {
    context.read<QuestionsBloc>().add(LoadQuestions(
          subCategoryId: _filterSubCategoryId,
          // Note: Bloc LoadQuestions currently only accepts subCategoryId.
          // We need to support filtering by mainCat, points, status in Bloc if we want to filter on server.
          // Or we filter locally in the view.
          // FirestoreService.getQuestions supports all filters.
          // But QuestionsBloc.LoadQuestions only has subCategoryId.
          // I should update QuestionsBloc to support all filters.
        ));
  }

  void _showQuestionDialog(BuildContext context,
      List<MainCategoryModel> mainCats, List<SubCategoryModel> subCats,
      [SeenjeemQuestionModel? question]) {
    final isEditing = question != null;

    final questionTextController =
        TextEditingController(text: question?.questionTextAr ?? '');
    final answerTextController =
        TextEditingController(text: question?.answerTextAr ?? '');

    String? subCategoryId = question?.subCategoryId ?? _filterSubCategoryId;
    int points = question?.points ?? 200;
    String status = question?.status ?? 'active';
    String? questionMediaUrl = question?.questionMediaUrl;
    String? answerMediaUrl = question?.answerMediaUrl;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Question' : 'Add Question'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 600,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sub Category *',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: subCategoryId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: subCats
                        .fold<Map<String, SubCategoryModel>>(
                          {},
                          (map, cat) => map..putIfAbsent(cat.id, () => cat),
                        )
                        .values
                        .map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Text(
                            '${mainCats.where((m) => m.id == cat.mainCategoryId).firstOrNull?.nameAr ?? ''} - ${cat.nameAr}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => subCategoryId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Question Text (Arabic) *',
                    controller: questionTextController,
                    textDirection: TextDirection.rtl,
                    maxLines: 3,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Answer Text (Arabic) *',
                    controller: answerTextController,
                    textDirection: TextDirection.rtl,
                    maxLines: 3,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Points *',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: points,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: const [
                      DropdownMenuItem(value: 200, child: Text('200 Points')),
                      DropdownMenuItem(value: 400, child: Text('400 Points')),
                      DropdownMenuItem(value: 600, child: Text('600 Points')),
                    ],
                    onChanged: (value) {
                      setDialogState(() => points = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Question Media (Optional)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  if (questionMediaUrl != null) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            questionMediaUrl ?? '',
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
                                setDialogState(() => questionMediaUrl = null),
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
                    label: const Text('Upload Question Media'),
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
                                final url = await _firestoreService.uploadMedia(
                                  file.bytes!,
                                  file.name,
                                  'questions',
                                );
                                setDialogState(() {
                                  questionMediaUrl = url;
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
                  const SizedBox(height: 16),
                  const Text(
                    'Answer Media (Optional)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  if (answerMediaUrl != null) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            answerMediaUrl ?? "",
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
                                setDialogState(() => answerMediaUrl = null),
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
                    label: const Text('Upload Answer Media'),
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
                                final url = await _firestoreService.uploadMedia(
                                  file.bytes!,
                                  file.name,
                                  'questions',
                                );
                                setDialogState(() {
                                  answerMediaUrl = url;
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
                  const SizedBox(height: 16),
                  const Text(
                    'Status *',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                          value: 'disabled', child: Text('Disabled')),
                      DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    ],
                    onChanged: (value) {
                      setDialogState(() => status = value!);
                    },
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
                      if (questionTextController.text.isEmpty ||
                          answerTextController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Question and answer text are required')),
                        );
                        return;
                      }

                      if (subCategoryId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Sub category is required')),
                        );
                        return;
                      }

                      final data = {
                        'sub_category_id': subCategoryId,
                        'question_text_ar': questionTextController.text,
                        'answer_text_ar': answerTextController.text,
                        'question_media_url': questionMediaUrl,
                        'answer_media_url': answerMediaUrl,
                        'points': points,
                        'status': status,
                      };

                      final bloc = context.read<QuestionsBloc>();

                      if (isEditing) {
                        bloc.add(UpdateQuestion(question.id, data));
                      } else {
                        bloc.add(CreateQuestion(data));
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

  void _showViewDialog(
      SeenjeemQuestionModel question, List<SubCategoryModel> subCats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Question Details'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 600,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildViewField(
                    'Sub Category',
                    subCats
                            .where((s) => s.id == question.subCategoryId)
                            .firstOrNull
                            ?.nameAr ??
                        'N/A'),
                const SizedBox(height: 12),
                _buildViewField('Question (Arabic)', question.questionTextAr,
                    rtl: true),
                const SizedBox(height: 12),
                if (question.questionMediaUrl != null) ...[
                  const Text('Question Media:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(question.questionMediaUrl!,
                        height: 200, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 12),
                ],
                _buildViewField('Answer (Arabic)', question.answerTextAr,
                    rtl: true),
                const SizedBox(height: 12),
                if (question.answerMediaUrl != null) ...[
                  const Text('Answer Media:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(question.answerMediaUrl!,
                        height: 200, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 12),
                ],
                _buildViewField('Points', question.points.toString()),
                const SizedBox(height: 12),
                _buildViewField('Status', question.status),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildViewField(String label, String value, {bool rtl = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14),
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        ),
      ],
    );
  }

  // Keeping Import logic locally for now, could be moved to Bloc later
  Future<void> _handleImport(
      List<MainCategoryModel> mainCats,
      List<SubCategoryModel> subCats,
      List<SeenjeemQuestionModel> existingQuestions) async {
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

      int successCount = 0;
      int errorCount = 0;
      int skippedCount = 0;
      List<String> errors = [];

      final bloc = context.read<QuestionsBloc>();

      for (final row in rows) {
        try {
          final mainCat = mainCats.firstWhere(
            (cat) => cat.nameAr == row['main_category_name_ar'],
            orElse: () => throw Exception('Main category not found'),
          );

          final subCat = subCats.firstWhere(
            (cat) =>
                cat.mainCategoryId == mainCat.id &&
                cat.nameAr == row['sub_category_name_ar'],
            orElse: () => throw Exception('Sub category not found'),
          );

          final points = int.parse(row['points'].toString());
          if (![200, 400, 600].contains(points)) {
            errors.add('Invalid points: ${row['points']}');
            errorCount++;
            continue;
          }

          final existing = existingQuestions.any(
            (q) => q.subCategoryId == subCat.id && q.points == points,
          );
          if (existing) {
            skippedCount++;
            continue;
          }

          // Directly using service here to avoid flooding Bloc (no batch create yet)
          await _firestoreService.createQuestion({
            'sub_category_id': subCat.id,
            'question_text_ar': row['question_text_ar'],
            'answer_text_ar': row['answer_text_ar'],
            'question_media_url': row['question_media_url'],
            'answer_media_url': row['answer_media_url'],
            'points': points,
            'status': row['status'] ?? 'active',
          });
          successCount++;
        } catch (e) {
          errors.add('Row error: $e');
          errorCount++;
        }
      }

      // Reload
      bloc.add(LoadQuestions(
          subCategoryId: _filterSubCategoryId)); // Refresh filtered view if any

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

  void _handleDownloadTemplate() {
    _excelService.downloadTemplate('questions');
  }

  void _handleExport(List<SeenjeemQuestionModel> questions) {
    _excelService.exportQuestions(questions);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<QuestionsBloc, QuestionsState>(
          listener: (context, state) {
            if (state is QuestionsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.danger),
              );
            } else if (state is QuestionOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.secondary),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<CategoriesBloc, CategoriesState>(
        builder: (context, categoriesState) {
          List<MainCategoryModel> mainCategories = [];
          List<SubCategoryModel> subCategories = [];

          if (categoriesState is CategoriesLoaded) {
            mainCategories = categoriesState.mainCategories;
            subCategories = categoriesState.subCategories;
          }

          // Filter subcategories for dropdown based on selected main category
          List<SubCategoryModel> filteredSubCategories =
              _filterMainCategoryId != null
                  ? subCategories
                      .where(
                          (sub) => sub.mainCategoryId == _filterMainCategoryId)
                      .toList()
                  : subCategories;

          return BlocBuilder<QuestionsBloc, QuestionsState>(
            builder: (context, questionsState) {
              List<SeenjeemQuestionModel> questions = [];
              bool isLoading = questionsState is QuestionsLoading ||
                  categoriesState is CategoriesLoading;

              if (questionsState is QuestionsLoaded) {
                questions = questionsState.questions;
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
                        _buildHeader(
                            context, questions, mainCategories, subCategories),
                        const SizedBox(height: 16),
                        _buildWarningBanner(),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFilters(
                                    mainCategories, filteredSubCategories),
                                const SizedBox(height: 24),
                                Expanded(
                                  child: _buildDataTable(
                                      questions, mainCategories, subCategories),
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
        },
      ),
    );
  }

  Future<void> _confirmDeleteQuestion(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(children: [
          Icon(Icons.delete_rounded, color: AppColors.danger, size: 22),
          SizedBox(width: 10),
          Text('Delete Question', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        content: const Text('Are you sure you want to delete this question? This cannot be undone.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<QuestionsBloc>().add(DeleteQuestion(id));
    }
  }

  Future<void> _deleteAllQuestions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.danger, size: 22),
            SizedBox(width: 10),
            Text('Delete All Questions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'This will permanently delete ALL questions from the database. This cannot be undone.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _syncing = true);
    try {
      await _firestoreService.deleteAllQuestions();
      _loadQuestions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('All questions deleted'),
          backgroundColor: AppColors.danger,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _showSyncDialog(BuildContext context, List<SubCategoryModel> subCats) {
    showDialog(
      context: context,
      builder: (ctx) => _SyncDialog(
        subCats: subCats,
        sheetsService: _sheetsService,
        onSync: (selectedTabs) {
          Navigator.of(ctx).pop();
          _syncMultipleTabs(subCats, selectedTabs);
        },
      ),
    );
  }

  Future<void> _syncMultipleTabs(List<SubCategoryModel> subCats, List<String> tabs) async {
    setState(() => _syncing = true);
    int totalCount = 0;
    final failed = <String>[];
    for (final tab in tabs) {
      try {
        final count = await _sheetsService.syncQuestionsFromTab(tab, subCats, _firestoreService);
        totalCount += count;
      } catch (e) {
        failed.add(tab);
      }
    }
    _loadQuestions();
    if (mounted) {
      if (failed.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Synced $totalCount questions from ${tabs.length} tab(s)'),
          backgroundColor: AppColors.success,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Synced $totalCount questions. Failed: ${failed.join(", ")}'),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 6),
        ));
      }
      setState(() => _syncing = false);
    }
  }


  Widget _buildHeader(
      BuildContext context,
      List<SeenjeemQuestionModel> questions,
      List<MainCategoryModel> mainCats,
      List<SubCategoryModel> subCats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Questions',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage quiz questions for SeenJeem game board',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
        Row(
          children: [
            ElevatedButton.icon(
              icon: _syncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.sync_rounded, size: 18),
              label: Text(_syncing ? 'Syncing...' : 'Sync Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _syncing ? null : () => _showSyncDialog(context, subCats),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_sweep_rounded, size: 18),
              label: const Text('Delete All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _syncing ? null : _deleteAllQuestions,
            ),
            const SizedBox(width: 12),
            CustomButton(
              text: 'Add Question',
              icon: Icons.add,
              onPressed: () => _showQuestionDialog(context, mainCats, subCats),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.yellow[50],
        border: Border.all(color: Colors.yellow[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.yellow[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Important: Each sub-category must have exactly ONE question for each point value (200, 400, 600). The system prevents duplicate point values per sub-category.',
              style: TextStyle(fontSize: 13, color: Colors.yellow[900]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(List<MainCategoryModel> mainCategories,
      List<SubCategoryModel> filteredSubCategories) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.filter_list, color: Colors.grey[400]),
            const SizedBox(width: 8),
            const Text('Filters',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Search questions or answers...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() {
                        _searchQuery = '';
                        _currentPage = 0;
                      });
                    },
                  )
                : null,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
          onChanged: (v) => setState(() {
            _searchQuery = v.trim().toLowerCase();
            _currentPage = 0;
          }),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: (mainCategories.any((cat) =>
                        cat.id == _filterMainCategoryId && cat.isActive))
                    ? _filterMainCategoryId
                    : null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Main Categories'),
                  ),
                  ...mainCategories
                      .where((cat) => cat.isActive)
                      .fold<Map<String, MainCategoryModel>>(
                        {},
                        (map, cat) => map..putIfAbsent(cat.id, () => cat),
                      )
                      .values
                      .map((cat) {
                    return DropdownMenuItem<String?>(
                      value: cat.id,
                      child: Text(cat.nameAr),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _filterMainCategoryId = value;
                    _filterSubCategoryId = null;
                  });
                  _loadQuestions();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: (filteredSubCategories.any((cat) =>
                        cat.id == _filterSubCategoryId && cat.isActive))
                    ? _filterSubCategoryId
                    : null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Sub Categories'),
                  ),
                  ...filteredSubCategories
                      .where((cat) => cat.isActive)
                      .fold<Map<String, SubCategoryModel>>(
                        {},
                        (map, cat) => map..putIfAbsent(cat.id, () => cat),
                      )
                      .values
                      .map((cat) {
                    return DropdownMenuItem<String?>(
                      value: cat.id,
                      child: Text(cat.nameAr),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => _filterSubCategoryId = value);
                  _loadQuestions();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataTable(List<SeenjeemQuestionModel> questions,
      List<MainCategoryModel> mainCats, List<SubCategoryModel> subCats) {
    List<SeenjeemQuestionModel> filteredQuestions = questions.where((q) {
      if (_filterPoints != null && q.points != _filterPoints) return false;
      if (_filterStatus != null && q.status != _filterStatus) return false;
      if (_filterMainCategoryId != null && _filterSubCategoryId == null) {
        final sub = subCats.where((s) => s.id == q.subCategoryId).firstOrNull;
        if (sub?.mainCategoryId != _filterMainCategoryId) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final matchQ = q.questionTextAr.toLowerCase().contains(_searchQuery);
        final matchA = q.answerTextAr.toLowerCase().contains(_searchQuery);
        final subName = subCats.where((s) => s.id == q.subCategoryId).firstOrNull?.nameAr.toLowerCase() ?? '';
        final matchSub = subName.contains(_searchQuery);
        if (!matchQ && !matchA && !matchSub) return false;
      }
      return true;
    }).toList();

    final totalItems = filteredQuestions.length;
    final totalPages = (totalItems / _pageSize).ceil().clamp(1, 999999);
    final safePage = _currentPage.clamp(0, totalPages - 1);
    final pageQuestions = filteredQuestions.skip(safePage * _pageSize).take(_pageSize).toList();

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Scrollbar(
                controller: _verticalScrollCtrl,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _verticalScrollCtrl,
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    controller: _horizScrollCtrl,
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
                  columns: const [
                    DataColumn(label: Text('Sub Category', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Points', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Question', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Q.Image', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Answer', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('A.Image', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
                  ],
                  rows: pageQuestions.isEmpty
                      ? [
                          const DataRow(cells: [
                            DataCell(SizedBox()), DataCell(SizedBox()),
                            DataCell(Text('No questions found')),
                            DataCell(SizedBox()), DataCell(SizedBox()),
                            DataCell(SizedBox()), DataCell(SizedBox()),
                            DataCell(SizedBox()),
                          ])
                        ]
                      : pageQuestions.map((question) {
                          final subCatName = subCats
                                  .where((s) => s.id == question.subCategoryId)
                                  .firstOrNull
                                  ?.nameAr ??
                              'N/A';

                          Widget imageCell(String? url) {
                            if (url == null || url.isEmpty) {
                              return const Icon(Icons.image_not_supported_outlined,
                                  size: 20, color: Colors.grey);
                            }
                            return GestureDetector(
                              onTap: () => showDialog(
                                context: context,
                                builder: (_) => Dialog(
                                  child: Image.network(url, fit: BoxFit.contain),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  url,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.broken_image,
                                      size: 20,
                                      color: Colors.grey),
                                ),
                              ),
                            );
                          }

                          return DataRow(cells: [
                            DataCell(Text(subCatName,
                                style: const TextStyle(fontWeight: FontWeight.w500))),
                            DataCell(Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Text('${question.points}',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700])),
                            )),
                            DataCell(SizedBox(
                              width: 220,
                              child: Text(question.questionTextAr,
                                  overflow: TextOverflow.ellipsis, maxLines: 2),
                            )),
                            DataCell(imageCell(question.questionMediaUrl)),
                            DataCell(SizedBox(
                              width: 220,
                              child: Text(question.answerTextAr,
                                  overflow: TextOverflow.ellipsis, maxLines: 2),
                            )),
                            DataCell(imageCell(question.answerMediaUrl)),
                            DataCell(Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: question.status == 'active'
                                    ? AppColors.secondaryLight
                                    : AppColors.dangerLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                question.status.toUpperCase(),
                                style: TextStyle(
                                  color: question.status == 'active'
                                      ? AppColors.secondaryDark
                                      : AppColors.dangerDark,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            )),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility, size: 18),
                                  color: Colors.blue,
                                  onPressed: () => _showViewDialog(question, subCats),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  color: AppColors.primary,
                                  onPressed: () => _showQuestionDialog(context, mainCats, subCats, question),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.power_settings_new, size: 18),
                                  color: question.status == 'active'
                                      ? AppColors.danger
                                      : AppColors.secondary,
                                  onPressed: () => context.read<QuestionsBloc>().add(
                                      ToggleQuestionStatus(question.id, question.status != 'active')),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_rounded, size: 18),
                                  color: AppColors.danger,
                                  tooltip: 'Delete',
                                  onPressed: () => _confirmDeleteQuestion(context, question.id),
                                ),
                              ],
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        _buildPagination(totalItems, totalPages, safePage),
      ],
    );
  }

  Widget _buildPagination(int totalItems, int totalPages, int safePage) {
    if (totalItems == 0) return const SizedBox.shrink();
    final start = safePage * _pageSize + 1;
    final end = ((safePage + 1) * _pageSize).clamp(0, totalItems);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$start–$end of $totalItems',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: safePage > 0 ? () => setState(() => _currentPage = safePage - 1) : null,
              ),
              Text('${safePage + 1} / $totalPages',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: safePage < totalPages - 1
                    ? () => setState(() => _currentPage = safePage + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SyncDialog extends StatefulWidget {
  final List<SubCategoryModel> subCats;
  final GoogleSheetsService sheetsService;
  final void Function(List<String> selectedTabs) onSync;

  const _SyncDialog({
    required this.subCats,
    required this.sheetsService,
    required this.onSync,
  });

  @override
  State<_SyncDialog> createState() => _SyncDialogState();
}

class _SyncDialogState extends State<_SyncDialog> {
  bool _loading = true;
  List<String> _categoryTabs = [];
  Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _loadTabs();
  }

  Future<void> _loadTabs() async {
    try {
      final all = await widget.sheetsService.getWorksheetTitles();
      final cats = all.where((t) => t.trimRight().startsWith('الفئة')).toList();
      setState(() {
        _categoryTabs = cats;
        _selected = cats.toSet();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  bool get _allSelected => _categoryTabs.isNotEmpty && _selected.length == _categoryTabs.length;

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        _selected = {};
      } else {
        _selected = _categoryTabs.toSet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.sync_rounded, color: AppColors.primary, size: 22),
          SizedBox(width: 10),
          Text('Sync Questions from Google Sheets',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select which category tabs to sync from Google Sheets.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_categoryTabs.isEmpty)
              const Text('No category tabs found.',
                  style: TextStyle(color: AppColors.danger))
            else ...[
              InkWell(
                onTap: _toggleAll,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _allSelected,
                        tristate: true,
                        activeColor: AppColors.primary,
                        onChanged: (_) => _toggleAll(),
                      ),
                      const Text('Select All',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ),
              const Divider(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _categoryTabs.map((tab) {
                      return InkWell(
                        onTap: () => setState(() {
                          if (_selected.contains(tab)) {
                            _selected.remove(tab);
                          } else {
                            _selected.add(tab);
                          }
                        }),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _selected.contains(tab),
                                activeColor: AppColors.primary,
                                onChanged: (v) => setState(() {
                                  if (v == true) {
                                    _selected.add(tab);
                                  } else {
                                    _selected.remove(tab);
                                  }
                                }),
                              ),
                              Expanded(
                                child: Text(tab,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textPrimary)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _selected.isEmpty ? null : () => widget.onSync(_selected.toList()),
          child: Text('Sync (${_selected.length})'),
        ),
      ],
    );
  }
}
