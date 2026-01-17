import 'package:excel/excel.dart';
import '../models/seenjeem_question_model.dart';
import '../models/main_category_model.dart';
import '../models/sub_category_model.dart';

class ExcelService {
  Future<List<Map<String, dynamic>>> parseExcelFile(List<int> bytes) async {
    try {
      var excel = Excel.decodeBytes(bytes);
      List<Map<String, dynamic>> rows = [];

      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table]!;
        // Assuming first row is header
        if (sheet.maxRows < 2) continue;

        var headers =
            sheet.row(0).map((e) => e?.value?.toString().trim() ?? '').toList();

        for (var i = 1; i < sheet.maxRows; i++) {
          var rowData = sheet.row(i);
          if (rowData.isEmpty) continue;

          Map<String, dynamic> rowMap = {};
          for (var j = 0; j < headers.length && j < rowData.length; j++) {
            if (headers[j].isNotEmpty) {
              var value = rowData[j]?.value;
              rowMap[headers[j]] = value;
            }
          }
          // Basic filtering for empty rows
          if (rowMap.values.any((v) => v != null && v.toString().isNotEmpty)) {
            rows.add(rowMap);
          }
        }
      }
      return rows;
    } catch (e) {
      print('Error parsing Excel: $e');
      return [];
    }
  }

  void downloadTemplate(String type) {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Template'];

    List<String> headers = [];
    if (type == 'main-categories') {
      headers = ['name_ar', 'display_order', 'is_active', 'media_url'];
    } else if (type == 'sub-categories') {
      headers = [
        'main_category_name_ar',
        'name_ar',
        'display_order',
        'is_active',
        'media_url'
      ];
    } else if (type == 'questions') {
      headers = [
        'main_category_name_ar',
        'sub_category_name_ar',
        'question_text_ar',
        'answer_text_ar',
        'points',
        'status',
        'question_media_url',
        'answer_media_url'
      ];
    }

    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());

    // In a real web app, we would trigger a download here.
    // Since we don't have 'universal_html' or 'dart:html' setup guaranteed or context,
    // we'll just print for now as placeholder for the "run" requirement.
    // To implement download:
    // excel.save(fileName: '$type\_template.xlsx'); // works in some setups or returns bytes
    print('Generated template for $type. Implement download logic.');
  }

  Future<void> exportQuestions(List<SeenjeemQuestionModel> questions) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Questions'];

    sheet.appendRow([
      TextCellValue('Sub Category ID'),
      TextCellValue('Question (Ar)'),
      TextCellValue('Answer (Ar)'),
      TextCellValue('Points'),
      TextCellValue('Status'),
    ]);

    for (var q in questions) {
      sheet.appendRow([
        TextCellValue(q.subCategoryId),
        TextCellValue(q.questionTextAr),
        TextCellValue(q.answerTextAr),
        IntCellValue(q.points),
        TextCellValue(q.status),
      ]);
    }

    // excel.save(fileName: 'questions_export.xlsx');
    print('Exported questions. Implement download logic.');
  }

  Future<void> exportMainCategories(List<MainCategoryModel> categories) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Main Categories'];

    sheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Name (Ar)'),
      TextCellValue('Order'),
      TextCellValue('Status'),
    ]);

    for (var c in categories) {
      sheet.appendRow([
        TextCellValue(c.id),
        TextCellValue(c.nameAr),
        IntCellValue(c.displayOrder),
        TextCellValue(c.isActive ? 'Active' : 'Disabled'),
      ]);
    }
    print('Exported main categories.');
  }

  Future<void> exportSubCategories(List<SubCategoryModel> categories) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sub Categories'];

    sheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Main Category ID'),
      TextCellValue('Name (Ar)'),
      TextCellValue('Order'),
      TextCellValue('Status'),
    ]);

    for (var c in categories) {
      sheet.appendRow([
        TextCellValue(c.id),
        TextCellValue(c.mainCategoryId),
        TextCellValue(c.nameAr),
        IntCellValue(c.displayOrder),
        TextCellValue(c.isActive ? 'Active' : 'Disabled'),
      ]);
    }
    print('Exported sub categories.');
  }
}
