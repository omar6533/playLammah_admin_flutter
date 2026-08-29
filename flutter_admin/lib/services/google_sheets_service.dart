import 'dart:convert';
import 'package:gsheets/gsheets.dart';
import 'package:googleapis_auth/auth_io.dart';
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

  /// DEBUG: Returns the first [count] raw rows from the sheet (no filtering).
  Future<String> debugReadFirstRows({int count = 5}) async {
    _gsheets = null;
    _spreadsheet = null;
    final ws = await _sheet();
    if (ws == null) return 'Worksheet not found';
    final all = await ws.values.allRows(fromColumn: 2);
    final sb = StringBuffer();
    sb.writeln('Total sheet rows: ${all.length}');
    for (var ri = 0; ri < all.length && ri < count; ri++) {
      final row = all[ri];
      sb.writeln('--- Row $ri (${row.length} cols) ---');
      for (var ci = 0; ci < row.length; ci++) {
        if (row[ci].isNotEmpty) sb.writeln('  [$ci]: ${row[ci]}');
      }
    }
    return sb.isEmpty ? '(all empty)' : sb.toString();
  }

  /// DEBUG: Scans ALL rows and returns any row that has content past column 3
  /// (i.e. has description or image data). Used to diagnose image column index.
  Future<String> debugFindImageRows() async {
    _gsheets = null;
    _spreadsheet = null;
    final ws = await _sheet();
    if (ws == null) return 'Worksheet not found';
    final all = await ws.values.allRows(fromColumn: 2);
    final sb = StringBuffer();
    sb.writeln('Total rows: ${all.length}');
    var found = 0;
    for (var ri = 0; ri < all.length; ri++) {
      final row = all[ri];
      // Show rows with content beyond the 4 base columns
      final hasExtra = row.length > 4 && row.skip(4).any((c) => c.isNotEmpty);
      if (hasExtra) {
        found++;
        sb.writeln('--- Row $ri (${row.length} cols) ---');
        for (var ci = 0; ci < row.length; ci++) {
          if (row[ci].isNotEmpty) sb.writeln('  [$ci]: ${row[ci]}');
        }
      }
    }
    if (found == 0) sb.writeln('(no rows with content past col index 3)');
    return sb.toString();
  }

  /// Fetches cell-property hyperlinks for the image column (P) from the
  /// Sheets REST API. The gsheets package only reads cell values — it cannot
  /// read URLs stored via "Insert Link" (Ctrl+K). This method fills that gap.
  /// Returns a map of 0-based sheet row index → URL.
  Future<Map<int, String>> _fetchImageColumnHyperlinks() async {
    try {
      final credsJson = jsonDecode(kGoogleServiceAccountJson) as Map<String, dynamic>;
      final credentials = ServiceAccountCredentials.fromJson(credsJson);
      final scopes = ['https://www.googleapis.com/auth/spreadsheets.readonly'];
      final client = await clientViaServiceAccount(credentials, scopes);
      try {
        // Image column index 14 (from fromColumn:2) = column P (B=0 → P=14, so sheet col = 2+14 = 16 = P)
        final uri = Uri.https(
          'sheets.googleapis.com',
          '/v4/spreadsheets/$kSpreadsheetId',
          {
            'ranges': '$kCategorySheetName!P:P',
            'fields': 'sheets(data(rowData(values(hyperlink))))',
          },
        );
        final response = await client.get(uri);
        if (response.statusCode != 200) return {};
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final sheets = body['sheets'] as List?;
        if (sheets == null || sheets.isEmpty) return {};
        final data = (sheets[0] as Map)['data'] as List?;
        if (data == null || data.isEmpty) return {};
        final rowData = (data[0] as Map)['rowData'] as List?;
        if (rowData == null) return {};
        final result = <int, String>{};
        for (int i = 0; i < rowData.length; i++) {
          final values = ((rowData[i] as Map?)?['values'] as List?);
          if (values == null || values.isEmpty) continue;
          final hyperlink = (values[0] as Map?)?['hyperlink'] as String?;
          if (hyperlink != null && hyperlink.isNotEmpty) {
            result[i] = hyperlink;
          }
        }
        return result;
      } finally {
        client.close();
      }
    } catch (_) {
      return {};
    }
  }

  /// Returns data rows from the categories sheet, skipping title/header rows.
  /// Each row is [mainCode, mainName, subCode, subName, description, mediaUrl].
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

    // Fetch cell-property hyperlinks for the image column (P) separately,
    // because "Insert Link" stores the URL in a cell property, not the value.
    final hyperlinks = await _fetchImageColumnHyperlinks();

    // Merge hyperlinks into raw rows before filtering
    final allMerged = <List<String>>[];
    for (int i = 0; i < all.length; i++) {
      final row = List<String>.from(all[i]);
      final link = hyperlinks[i];
      if (link != null && link.isNotEmpty) {
        // Ensure the list is long enough to hold index 14
        while (row.length <= 14) row.add('');
        // Only overwrite if the cell value isn't already a usable URL
        if (_extractUrl(row[14]).isEmpty) row[14] = link;
      }
      allMerged.add(row);
    }

    // Skip truly empty rows and known header rows.
    // NOTE: merged-cell continuation rows have an empty mainCode (row[0]) but a
    // non-empty subCode (row[2]). We must keep those rows so parseCategoryRows
    // can inherit the main-category via lastMainCode/lastMainName.
    const headerValues = {'كود الفئة', 'كود الصنف', 'الفئة', 'الصنف', 'code', 'header'};
    final filtered = allMerged.where((row) {
      if (row.isEmpty) return false;
      final mainCode = row[0].trim();
      final subCode  = row.length > 2 ? row[2].trim() : '';
      if (mainCode.isEmpty && subCode.isEmpty) return false;
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
  ///   [4]=نبذة تعريفية للأصناف  [14]=ارفاق صورة للصنف (media_url)
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
      // Column O (index 14 from fromColumn:2) = ارفاق صورة للصنف
      final mediaUrl    = row.length > 14 ? _extractUrl(row[14]) : '';
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
