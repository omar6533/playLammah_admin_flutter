import 'package:gsheets/gsheets.dart';
import '../config/google_config.dart';
import '../models/main_category_model.dart';
import '../models/sub_category_model.dart';
import 'firestore_service.dart';

class GoogleSheetsService {
  // Non-static: a fresh GSheets (and fresh JWT) is created for each sync call,
  // avoiding invalid_grant errors caused by stale cached credentials.
  GSheets? _gsheets;
  Spreadsheet? _spreadsheet;

  Future<Worksheet?> _sheet({bool refresh = false}) async {
    if (refresh || _spreadsheet == null || _gsheets == null) {
      _gsheets = GSheets(kGoogleServiceAccountJson);
      // FORMULA render returns raw formula text for hyperlink cells
      // (e.g. =HYPERLINK("drive_url","display_text")) so we can extract the URL.
      // Plain text cells are unaffected — they still return their raw value.
      _spreadsheet = await _gsheets!.spreadsheet(
        kSpreadsheetId,
        render: ValueRenderOption.formula,
      );
    }
    // Iterate all sheets and compare stripped/normalized titles
    for (final sheet in _spreadsheet!.sheets) {
      final t = sheet.title.replaceAll(RegExp(r'\s'), '');
      final target = kCategorySheetName.replaceAll(RegExp(r'\s'), '');
      if (t == target) return sheet;
    }
    // Fallback: sheet whose title contains both key Arabic words
    for (final sheet in _spreadsheet!.sheets) {
      if (sheet.title.contains('تعريف') && sheet.title.contains('فئات')) {
        return sheet;
      }
    }
    // Last resort: sheet at index 1 (second tab, usually تعريف الفئات)
    if (_spreadsheet!.sheets.length > 1) return _spreadsheet!.sheets[1];
    return null;
  }

  /// Returns all worksheet titles — useful for diagnosing name mismatches.
  Future<List<String>> getWorksheetTitles() async {
    _gsheets ??= GSheets(kGoogleServiceAccountJson);
    _spreadsheet ??= await _gsheets!.spreadsheet(kSpreadsheetId);
    return _spreadsheet!.sheets.map((s) => s.title).toList();
  }

  // ── Read ─────────────────────────────────────────────────────────────────

  /// Returns data rows from the categories sheet, skipping title/header rows.
  /// Each row is [mainCode, mainName, subCode, subName].
  Future<List<List<String>>> readCategoryRows() async {
    final ws = await _sheet();
    if (ws == null) {
      final titles = await getWorksheetTitles();
      throw Exception(
        'Category worksheet not found. '
        'Available tabs: ${titles.join(" | ")}',
      );
    }
    // Column A is empty in this sheet; data starts at column B (fromColumn: 2)
    final all = await ws.values.allRows(fromColumn: 2);
    if (all.isEmpty) {
      throw Exception('Worksheet "${ws.title}" found but contains 0 rows.');
    }
    // Skip truly empty rows and known header rows.
    // NOTE: merged-cell continuation rows have an empty mainCode (row[0]) but a
    // non-empty subCode (row[2]). We must keep those rows so parseCategoryRows
    // can inherit the main-category via lastMainCode/lastMainName.
    const headerValues = {'كود الفئة', 'كود الصنف', 'الفئة', 'الصنف', 'code', 'header'};
    final filtered = all.where((row) {
      if (row.isEmpty) return false;
      final mainCode = row[0].trim();
      final subCode  = row.length > 2 ? row[2].trim() : '';
      // Keep only rows that carry something useful
      if (mainCode.isEmpty && subCode.isEmpty) return false;
      // Drop header rows
      if (headerValues.contains(mainCode) ||
          headerValues.contains(mainCode.toLowerCase())) return false;
      return true;
    }).toList();
    if (filtered.isEmpty) {
      final sample = all.skip(5).take(5).map((r) => r.join(' | ')).join(' /// ');
      throw Exception(
        '${all.length} rows (from col B) but all filtered. Sample rows 6-10: $sample',
      );
    }
    return filtered;
  }

  /// Extracts a plain URL from a cell value that may be:
  ///   - A raw URL: returned as-is
  ///   - A HYPERLINK formula: =HYPERLINK("url","text") → returns url
  ///   - Plain display text (not a URL): returns empty string
  String _extractUrl(String cell) {
    final c = cell.trim();
    if (c.isEmpty) return '';
    // Handle =HYPERLINK("url") or =HYPERLINK("url","text")
    if (c.startsWith('=HYPERLINK(')) {
      final match = RegExp(r'=HYPERLINK\("([^"]+)"').firstMatch(c);
      if (match != null) return match.group(1) ?? '';
    }
    // Already a plain URL
    if (c.startsWith('http://') || c.startsWith('https://')) return c;
    // Drive open URL (sometimes starts with drive://)
    if (c.startsWith('drive://')) return c;
    return '';
  }

  /// Parses raw rows into deduplicated main-category and sub-category maps.
  /// Columns (after fromColumn:2 skips the empty col A):
  ///   [0]=كود الفئة  [1]=اسم الفئة  [2]=كود الصنف  [3]=اسم الصنف
  ///   [4]=نبذة تعريفية للأصناف  [5]=ارفاق صورة للصنف (media_url)
  ({
    List<Map<String, String>> mainCategories,
    List<Map<String, String>> subCategories,
  })
  parseCategoryRows(List<List<String>> rows) {
    final mainMap = <String, Map<String, String>>{};
    final subs = <Map<String, String>>[];
    final seenSubCodes = <String>{};
    // Track last-seen main code/name to handle merged-cell style sheets
    // where the main category code only appears in the first row of each group
    String lastMainCode = '';
    String lastMainName = '';

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final mainCode = row.isNotEmpty ? row[0].trim() : '';
      final mainName = row.length > 1 ? row[1].trim() : '';
      // [2] = كود الصنف, [3] = اسم الصنف, [5] = نبذة تعريفية
      final subCode    = row.length > 2 ? row[2].trim() : '';
      final subName    = row.length > 3 ? row[3].trim() : '';
      final description = row.length > 4 ? row[4].trim() : '';
      // Column G may be a =HYPERLINK("url","text") formula; _extractUrl handles both
      final mediaUrl    = row.length > 5 ? _extractUrl(row[5]) : '';
      // Row number in the sheet data (1-based)
      final rowNumber  = (i + 1).toString();

      // Inherit mainCode from previous row if this is a continuation row
      final effectiveMainCode = mainCode.isNotEmpty ? mainCode : lastMainCode;
      final effectiveMainName = mainName.isNotEmpty ? mainName : lastMainName;

      if (mainCode.isNotEmpty) {
        lastMainCode = mainCode;
        lastMainName = mainName;
      }

      if (effectiveMainCode.isEmpty) continue;

      mainMap.putIfAbsent(effectiveMainCode, () => {
            'code': effectiveMainCode,
            'name_ar': effectiveMainName,
          });

      if (subCode.isNotEmpty && subName.isNotEmpty &&
          !seenSubCodes.contains(subCode)) {
        seenSubCodes.add(subCode);
        subs.add({
          'code': subCode,
          'name_ar': subName,
          'description': description,
          'media_url': mediaUrl,
          'main_category_code': effectiveMainCode,
          'row_number': rowNumber,
        });
      }
    }

    return (
      mainCategories: mainMap.values.toList(),
      subCategories: subs,
    );
  }

  // ── Sheet → Firestore ────────────────────────────────────────────────────

  /// Reads the Google Sheet and creates/updates categories in Firestore
  /// to match. This is the canonical "Sync Now" direction.
  /// Returns a summary of what was created/updated/skipped.
  Future<({int mainCreated, int mainUpdated, int subCreated, int subUpdated, int skipped})>
      syncFromSheetToFirestore(FirestoreService firestoreService) async {
    // Force a completely fresh GSheets instance and connection each sync
    // to avoid invalid_grant errors from stale JWT state.
    _gsheets = null;
    _spreadsheet = null;
    final rows = await readCategoryRows();
    final parsed = parseCategoryRows(rows);

    // Load current Firestore state once
    final existingMain = await firestoreService.getMainCategories();
    final existingSub = await firestoreService.getSubCategories();

    // Remove duplicate sub-category docs (keep first occurrence, delete the rest)
    final seenIds = <String>{};
    for (final sub in existingSub) {
      if (!seenIds.add(sub.code)) {
        await firestoreService.deleteSubCategory(sub.id);
      }
    }
    // Re-load after cleanup so existingSub is deduplicated
    final cleanSub = await firestoreService.getSubCategories();

    int mainCreated = 0, mainUpdated = 0, subCreated = 0, subUpdated = 0, skipped = 0;

    // ── Main categories ───────────────────────────────────────────────────
    for (int mi = 0; mi < parsed.mainCategories.length; mi++) {
      final sheetMain = parsed.mainCategories[mi];
      final code = sheetMain['code'] ?? '';
      final name = sheetMain['name_ar'] ?? '';
      if (code.isEmpty || name.isEmpty) { skipped++; continue; }

      final existing = existingMain.where((m) => m.code == code).firstOrNull;
      if (existing == null) {
        await firestoreService.createMainCategory({
          'code': code,
          'name_ar': name,
          'display_order': mi,
          'is_active': true,
          'status': 'active',
        });
        mainCreated++;
      } else if (existing.nameAr != name || existing.displayOrder != mi) {
        await firestoreService.updateMainCategory(existing.id, {
          'code': code,
          'name_ar': name,
          'display_order': mi,
        });
        mainUpdated++;
      } else {
        skipped++;
      }
    }

    // Re-load main cats so we have fresh IDs for sub-category linking
    final freshMain = await firestoreService.getMainCategories();

    // ── Sub categories ────────────────────────────────────────────────────
    for (final sheetSub in parsed.subCategories) {
      final subCode = sheetSub['code'] ?? '';
      final subName = sheetSub['name_ar'] ?? '';
      final mainCode = sheetSub['main_category_code'] ?? '';
      if (subCode.isEmpty || subName.isEmpty) { skipped++; continue; }

      final parentMain = freshMain.where((m) => m.code == mainCode).firstOrNull;
      if (parentMain == null) { skipped++; continue; }

      final existing = cleanSub
          .where((s) => s.code == subCode)
          .firstOrNull;

      final description = sheetSub['description'] ?? '';
      final mediaUrl = sheetSub['media_url'] ?? '';
      final displayOrder = int.tryParse(sheetSub['row_number'] ?? '0') ?? 0;

      if (existing == null) {
        await firestoreService.createSubCategory({
          'code': subCode,
          'main_category_id': parentMain.id,
          'name_ar': subName,
          'description': description,
          'display_order': displayOrder,
          'is_active': true,
          'media_url': mediaUrl,
        });
        subCreated++;
      } else if (existing.nameAr != subName ||
          existing.mainCategoryId != parentMain.id ||
          existing.description != description ||
          existing.displayOrder != displayOrder ||
          (mediaUrl.isNotEmpty && existing.mediaUrl != mediaUrl)) {
        await firestoreService.updateSubCategory(existing.id, {
          'code': subCode,
          'name_ar': subName,
          'description': description,
          'display_order': displayOrder,
          'main_category_id': parentMain.id,
          if (mediaUrl.isNotEmpty) 'media_url': mediaUrl,
        });
        subUpdated++;
      } else {
        skipped++;
      }
    }

    return (
      mainCreated: mainCreated,
      mainUpdated: mainUpdated,
      subCreated: subCreated,
      subUpdated: subUpdated,
      skipped: skipped,
    );
  }

  // ── Write / Sync ──────────────────────────────────────────────────────────

  /// Overwrites the data rows in the sheet to match the current Firestore state.
  /// Preserves the header/title rows (1–kCategoryHeaderRow).
  Future<void> syncCategoriesToSheet(
    List<MainCategoryModel> mainCats,
    List<SubCategoryModel> subCats,
  ) async {
    final ws = await _sheet();
    if (ws == null) return;

    // Build one row per (main, sub) pair.
    // Column A is empty in this sheet; data lives in B-E.
    // Prepend '' so writing from column 1 puts codes in the right place.
    final rows = <List<String>>[];
    for (final main in mainCats) {
      final children =
          subCats.where((s) => s.mainCategoryId == main.id).toList();
      if (children.isEmpty) {
        rows.add(['', main.code, main.nameAr, '', '']);
      } else {
        for (final sub in children) {
          rows.add(['', main.code, main.nameAr, sub.code, sub.nameAr]);
        }
      }
    }

    // Find how many data rows currently exist so we can blank any extras.
    // readCategoryRows already uses fromColumn:2 so oldCount is correct.
    int oldCount = 0;
    try {
      final existingData = await readCategoryRows();
      oldCount = existingData.length;
    } catch (_) {
      oldCount = 0;
    }

    // Write rows from column 1; each row has '' in index 0 (column A)
    // so the actual data lands in columns B-E matching the sheet's layout.
    if (rows.isNotEmpty) {
      await ws.values.insertRows(kCategoryDataRow, rows);
    }

    // Blank rows beyond the new data range
    final extras = oldCount - rows.length;
    if (extras > 0) {
      final emptyRows = List.generate(extras, (_) => ['', '', '', '', '']);
      await ws.values.insertRows(kCategoryDataRow + rows.length, emptyRows);
    }
  }
}
