import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/categories/categories_bloc.dart';
import '../blocs/categories/categories_state.dart';
import '../blocs/questions/questions_bloc.dart';
import '../blocs/questions/questions_event.dart';
import '../blocs/questions/questions_state.dart';
import '../models/seenjeem_question_model.dart';
import '../models/main_category_model.dart';
import '../models/sub_category_model.dart';
import '../services/firestore_service.dart';
import '../services/excel_service.dart';
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

  String? _filterMainCategoryId;
  String? _filterSubCategoryId;
  int? _filterPoints;
  String? _filterStatus;
  // String _searchQuery = ''; // Search logic needs to be in Bloc if supported or local filter

  bool _uploading = false;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
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
                        Container(
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
                              _buildDataTable(
                                  questions, mainCategories, subCategories),
                            ],
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
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Template'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[100],
                foregroundColor: Colors.grey[700],
              ),
              onPressed: _handleDownloadTemplate,
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Export'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[100],
                foregroundColor: Colors.grey[700],
              ),
              onPressed: () => _handleExport(questions),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: _importing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.upload, size: 18),
              label: Text(_importing ? 'Importing...' : 'Import'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
              onPressed: _importing
                  ? null
                  : () => _handleImport(mainCats, subCats, questions),
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
    // Apply local filters for fields not supported by backend yet (points, status)
    // FirestoreService supports them but we only pass subCategoryId to Bloc.
    // So we filter locally.
    List<SeenjeemQuestionModel> filteredQuestions = questions.where((q) {
      if (_filterPoints != null && q.points != _filterPoints) return false;
      if (_filterStatus != null && q.status != _filterStatus) return false;
      // Main category filter is implicit if we select MainCat but not SubCat?
      // If SubCat is selected, it belongs to MainCat.
      // If we only select MainCat, we need to filter questions belonging to that MainCat.
      if (_filterMainCategoryId != null && _filterSubCategoryId == null) {
        // Find if question's subcat belongs to maincat
        final sub = subCats.where((s) => s.id == q.subCategoryId).firstOrNull;
        if (sub?.mainCategoryId != _filterMainCategoryId) return false;
      }
      return true;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
              ),
              child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
        columns: const [
          DataColumn(
              label: Text('Sub Category',
                  style: TextStyle(fontWeight: FontWeight.w600))),
          DataColumn(
              label: Text('Points',
                  style: TextStyle(fontWeight: FontWeight.w600))),
          DataColumn(
              label: Text('Question',
                  style: TextStyle(fontWeight: FontWeight.w600))),
          DataColumn(
              label: Text('Answer',
                  style: TextStyle(fontWeight: FontWeight.w600))),
          DataColumn(
              label: Text('Status',
                  style: TextStyle(fontWeight: FontWeight.w600))),
          DataColumn(
              label: Text('Actions',
                  style: TextStyle(fontWeight: FontWeight.w600))),
        ],
        rows: filteredQuestions.isEmpty
            ? [
                const DataRow(cells: [
                  DataCell(SizedBox()),
                  DataCell(SizedBox()),
                  DataCell(Text('No questions found')),
                  DataCell(SizedBox()),
                  DataCell(SizedBox()),
                  DataCell(SizedBox()),
                ])
              ]
            : filteredQuestions.map((question) {
                final subCatName = subCats
                        .where((s) => s.id == question.subCategoryId)
                        .firstOrNull
                        ?.nameAr ??
                    'N/A';

                return DataRow(cells: [
                  DataCell(Text(subCatName,
                      style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      '${question.points}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.blue[700]),
                    ),
                  )),
                  DataCell(SizedBox(
                    width: 200,
                    child: Text(question.questionTextAr,
                        overflow: TextOverflow.ellipsis),
                  )),
                  DataCell(SizedBox(
                    width: 200,
                    child: Text(question.answerTextAr,
                        overflow: TextOverflow.ellipsis),
                  )),
                  DataCell(Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, size: 18),
                        color: Colors.blue,
                        onPressed: () => _showViewDialog(question, subCats),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        color: AppColors.primary,
                        onPressed: () => _showQuestionDialog(
                            context, mainCats, subCats, question),
                      ),
                      IconButton(
                        icon: const Icon(Icons.power_settings_new, size: 18),
                        color: question.status == 'active'
                            ? AppColors.danger
                            : AppColors.secondary,
                        onPressed: () => context.read<QuestionsBloc>().add(
                            ToggleQuestionStatus(
                                question.id, question.status != 'active')),
                      ),
                    ],
                  )),
                ]);
              }).toList(),
      ),
    );
  }
}
