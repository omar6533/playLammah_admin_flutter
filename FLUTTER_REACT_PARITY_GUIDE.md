# Flutter & React Implementation Parity Guide

This document shows side-by-side comparisons of how the React and Flutter implementations should work.

## Authentication

### React (TypeScript)
```typescript
import { supabase } from '../lib/supabase';

// Sign In
const { data, error } = await supabase.auth.signInWithPassword({
  email,
  password
});

// Sign Out
await supabase.auth.signOut();
```

### Flutter (Dart)
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

// Sign In
final response = await Supabase.instance.client.auth.signInWithPassword(
  email: email,
  password: password,
);

// Sign Out
await Supabase.instance.client.auth.signOut();
```

## Main Categories

### React - Fetch All
```typescript
const { data } = await supabase
  .from('main_categories')
  .select('*')
  .order('display_order');

return data;
```

### Flutter - Fetch All
```dart
final response = await _supabase
    .from('main_categories')
    .select()
    .order('display_order', ascending: true);

return (response as List)
    .map((json) => MainCategoryModel.fromJson(json))
    .toList();
```

### React - Create
```typescript
const { data } = await supabase
  .from('main_categories')
  .insert({
    name_ar: 'الفئة الجديدة',
    display_order: 0,
    is_active: true,
    media_url: null
  })
  .select()
  .single();
```

### Flutter - Create
```dart
final response = await _supabase
    .from('main_categories')
    .insert(category.toJson())
    .select()
    .single();

return MainCategoryModel.fromJson(response);
```

### React - Update
```typescript
const { data } = await supabase
  .from('main_categories')
  .update({ name_ar: 'اسم جديد' })
  .eq('id', id)
  .select()
  .single();
```

### Flutter - Update
```dart
final response = await _supabase
    .from('main_categories')
    .update(category.toJson())
    .eq('id', id)
    .select()
    .single();
```

### React - Delete
```typescript
await supabase
  .from('main_categories')
  .delete()
  .eq('id', id);
```

### Flutter - Delete
```dart
await _supabase
    .from('main_categories')
    .delete()
    .eq('id', id);
```

## Sub Categories (with Main Category Join)

### React - Fetch All
```typescript
const { data } = await supabase
  .from('sub_categories')
  .select('*, main_categories(name_ar)')
  .order('main_category_id')
  .order('display_order');
```

### Flutter - Fetch All
```dart
final response = await _supabase
    .from('sub_categories')
    .select('*, main_categories(name_ar)')
    .order('main_category_id')
    .order('display_order', ascending: true);

return (response as List)
    .map((json) => SubCategoryModel.fromJson(json))
    .toList();
```

## Questions (with Full Hierarchy)

### React - Fetch All
```typescript
const { data } = await supabase
  .from('questions')
  .select(`
    *,
    sub_categories(
      name_ar,
      main_categories(name_ar)
    )
  `)
  .order('sub_category_id')
  .order('points');
```

### Flutter - Fetch All
```dart
final response = await _supabase
    .from('questions')
    .select('*, sub_categories(name_ar, main_categories(name_ar))')
    .order('sub_category_id')
    .order('points', ascending: true);

return (response as List)
    .map((json) => SeenjeemQuestionModel.fromJson(json))
    .toList();
```

### React - Create Question
```typescript
const { data } = await supabase
  .from('questions')
  .insert({
    sub_category_id: subCategoryId,
    question_text_ar: 'السؤال',
    answer_text_ar: 'الإجابة',
    question_media_url: null,
    answer_media_url: null,
    points: 200,
    status: 'active'
  })
  .select(`
    *,
    sub_categories(
      name_ar,
      main_categories(name_ar)
    )
  `)
  .single();
```

### Flutter - Create Question
```dart
final response = await _supabase
    .from('questions')
    .insert(question.toJson())
    .select('*, sub_categories(name_ar, main_categories(name_ar))')
    .single();

return SeenjeemQuestionModel.fromJson(response);
```

## Excel Import Logic

### React - Import Main Categories
```typescript
const data = await parseExcelFile(file);

for (const row of data) {
  // Check for duplicates
  const existing = mainCategories.find(cat => cat.name_ar === row.name_ar);
  if (existing) {
    skippedCount++;
    continue;
  }

  // Create new
  await mainCategoriesApi.create({
    name_ar: row.name_ar,
    display_order: row.display_order || mainCategories.length,
    is_active: row.is_active === 'true',
    media_url: row.media_url || null,
  });
  successCount++;
}
```

### Flutter - Import Main Categories
```dart
final data = await _excelService.importFromExcel();

for (final row in data) {
  // Check for duplicates
  final existing = mainCategories.firstWhere(
    (cat) => cat.nameAr == row['name_ar'],
    orElse: () => null,
  );
  if (existing != null) {
    skippedCount++;
    continue;
  }

  // Create new
  final category = MainCategoryModel.fromExcel(row);
  await _supabaseService.createMainCategory(category);
  successCount++;
}
```

### React - Import Questions
```typescript
for (const row of data) {
  // Validate main category exists
  const mainCategory = mainCategories.find(
    cat => cat.name_ar === row.main_category_name_ar
  );
  if (!mainCategory) {
    errors.push(`Main category "${row.main_category_name_ar}" not found`);
    errorCount++;
    continue;
  }

  // Validate sub category exists
  const subCategory = subCategories.find(
    cat => cat.main_category_id === mainCategory.id &&
           cat.name_ar === row.sub_category_name_ar
  );
  if (!subCategory) {
    errors.push(`Sub category "${row.sub_category_name_ar}" not found`);
    errorCount++;
    continue;
  }

  // Validate points
  const points = parseInt(row.points);
  if (![200, 400, 600].includes(points)) {
    errors.push(`Invalid points "${row.points}"`);
    errorCount++;
    continue;
  }

  // Check for duplicates (same sub_category + points)
  const existing = questions.find(
    q => q.sub_category_id === subCategory.id && q.points === points
  );
  if (existing) {
    skippedCount++;
    continue;
  }

  // Create question
  await questionsApi.create({
    sub_category_id: subCategory.id,
    question_text_ar: row.question_text_ar,
    answer_text_ar: row.answer_text_ar,
    question_media_url: row.question_media_url || null,
    answer_media_url: row.answer_media_url || null,
    points: points,
    status: row.status || 'active',
  });
  successCount++;
}
```

### Flutter - Import Questions
```dart
final data = await _excelService.importFromExcel();

for (final row in data) {
  // Validate main category
  final mainCategory = mainCategories.firstWhere(
    (cat) => cat.nameAr == row['main_category_name_ar'],
    orElse: () => null,
  );
  if (mainCategory == null) {
    errors.add('Main category "${row['main_category_name_ar']}" not found');
    errorCount++;
    continue;
  }

  // Validate sub category
  final subCategory = subCategories.firstWhere(
    (cat) => cat.mainCategoryId == mainCategory.id &&
             cat.nameAr == row['sub_category_name_ar'],
    orElse: () => null,
  );
  if (subCategory == null) {
    errors.add('Sub category "${row['sub_category_name_ar']}" not found');
    errorCount++;
    continue;
  }

  // Validate points
  final points = int.tryParse(row['points']?.toString() ?? '') ?? 0;
  if (![200, 400, 600].contains(points)) {
    errors.add('Invalid points "${row['points']}"');
    errorCount++;
    continue;
  }

  // Check for duplicates
  final existing = questions.firstWhere(
    (q) => q.subCategoryId == subCategory.id && q.points == points,
    orElse: () => null,
  );
  if (existing != null) {
    skippedCount++;
    continue;
  }

  // Create question
  final question = SeenjeemQuestionModel.fromExcel(row, subCategory.id);
  await _supabaseService.createQuestion(question);
  successCount++;
}
```

## Excel Export Logic

### React - Export Main Categories
```typescript
const exportData = mainCategories.map(cat => ({
  name_ar: cat.name_ar,
  display_order: cat.display_order,
  is_active: cat.is_active ? 'true' : 'false',
  media_url: cat.media_url || '',
  created_at: formatDate(cat.created_at),
}));

exportToExcel(exportData, 'main_categories.xlsx', 'Main Categories');
```

### Flutter - Export Main Categories
```dart
final bytes = await _excelService.exportMainCategoriesToExcel(mainCategories);

// Download/save the file
// On web: use html package to trigger download
// On mobile: use path_provider and share package
```

## UI Patterns

### React - Status Toggle Button
```tsx
<button
  onClick={() => handleToggleStatus(item.id, !item.is_active)}
  className={item.is_active ? 'text-green-600' : 'text-gray-400'}
>
  <Power className="w-5 h-5" />
</button>
```

### Flutter - Status Toggle Button
```dart
IconButton(
  icon: Icon(
    Icons.power_settings_new,
    color: item.isActive ? Colors.green : Colors.grey,
  ),
  onPressed: () => handleToggleStatus(item.id, !item.isActive),
)
```

### React - Import Button
```tsx
<label className="...">
  <Upload className="w-5 h-5" />
  {importing ? 'Importing...' : 'Import'}
  <input
    ref={importInputRef}
    type="file"
    accept=".xlsx,.xls"
    onChange={handleImportExcel}
    className="hidden"
    disabled={importing}
  />
</label>
```

### Flutter - Import Button
```dart
ElevatedButton.icon(
  icon: Icon(Icons.upload),
  label: Text(importing ? 'Importing...' : 'Import'),
  onPressed: importing ? null : () async {
    setState(() => importing = true);
    await handleImportExcel();
    setState(() => importing = false);
  },
)
```

## Error Handling Pattern

### React
```typescript
try {
  // operation
} catch (error) {
  console.error('Error:', error);
  alert('Error message');
}
```

### Flutter
```dart
try {
  // operation
} catch (e) {
  print('Error: $e');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error message')),
  );
}
```

## Key Differences to Remember

1. **List Methods**:
   - React: `array.find()`, `array.map()`, `array.filter()`
   - Flutter: `list.firstWhere()`, `list.map()`, `list.where()`

2. **Async/Await**:
   - React: `async/await` with `Promise`
   - Flutter: `async/await` with `Future`

3. **Null Safety**:
   - React: Optional chaining `?.`
   - Flutter: Null-aware operators `?.` and null check `??`

4. **State Management**:
   - React: `useState()` hook
   - Flutter: `setState()` method

5. **Styling**:
   - React: Tailwind CSS classes
   - Flutter: Widget properties and ThemeData

## Summary

Both implementations:
- Use the same Supabase database
- Have identical API calls and queries
- Follow the same import/export logic
- Validate data the same way
- Have matching error handling
- Support the same features

The main differences are:
- Language syntax (TypeScript vs Dart)
- UI framework (React vs Flutter)
- File organization patterns
- State management approach
