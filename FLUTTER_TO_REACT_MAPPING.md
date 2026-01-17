# Flutter ↔ React Feature Mapping

Quick reference guide showing how React features map to Flutter implementation.

## Data Models

| React (TypeScript) | Flutter (Dart) | Notes |
|-------------------|----------------|-------|
| `MainCategory` | `MainCategoryModel` | Main game board categories |
| `SubCategory` | `SubCategoryModel` | Sub-categories under main |
| `Question` | `SeenjeemQuestionModel` | Questions with new structure |

## Services / APIs

| React | Flutter | Purpose |
|-------|---------|---------|
| `mainCategoriesApi.getAll()` | `SeenjeemService().getMainCategories()` | Fetch all main categories |
| `subCategoriesApi.getAll(mainId)` | `SeenjeemService().getSubCategories(mainCategoryId: mainId)` | Fetch sub categories |
| `questionsApi.getAll(filters)` | `SeenjeemService().getQuestions(...)` | Fetch questions with filters |
| `mediaUtils.uploadFile()` | `SeenjeemService().uploadMedia()` | Upload media to storage |
| `mediaUtils.deleteFile()` | `SeenjeemService().deleteMedia()` | Delete media from storage |

## UI Components

| React Component | Flutter Equivalent | Location |
|----------------|-------------------|----------|
| `Modal` | `showDialog()` with `AlertDialog` | Built-in Flutter |
| `Badge` | `Container` with custom styling | `lib/widgets/` |
| Custom buttons | `CustomButton` | `lib/widgets/custom_button.dart` |
| Data tables | `CustomDataTable` | `lib/widgets/custom_data_table.dart` |
| Text fields | `CustomTextField` | `lib/widgets/custom_text_field.dart` |

## Navigation

| React | Flutter (auto_route) | Purpose |
|-------|---------------------|---------|
| Direct navigation | `context.router.push(DashboardRoute())` | Navigate to page |
| `<Link>` | `AutoTabsRouter()` | Tab navigation |
| Route params | `@PathParam()` annotation | URL parameters |

## Categories Page

### React Implementation (`src/pages/Categories.tsx`)

```typescript
// State
const [activeTab, setActiveTab] = useState<'main' | 'sub'>('main');
const [mainCategories, setMainCategories] = useState<MainCategory[]>([]);

// Load data
const loadData = async () => {
  const [mainData, subData] = await Promise.all([
    mainCategoriesApi.getAll(),
    subCategoriesApi.getAll(selectedMainCategory),
  ]);
};

// Create
await mainCategoriesApi.create({
  name_ar: formData.name_ar,
  media_url: formData.media_url,
  display_order: formData.display_order,
  is_active: formData.is_active,
  status: formData.status,
});
```

### Flutter Implementation (TODO)

```dart
// State
int _activeTab = 0; // 0 = main, 1 = sub
List<MainCategoryModel> _mainCategories = [];

// Load data
Future<void> _loadData() async {
  final mainData = await _service.getMainCategories().first;
  final subData = await _service.getSubCategories(
    mainCategoryId: _selectedMainCategoryId
  ).first;
}

// Create
await _service.addMainCategory(MainCategoryModel(
  id: '',
  nameAr: _nameController.text,
  mediaUrl: _mediaUrl,
  displayOrder: _displayOrder,
  isActive: true,
  status: 'active',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
));
```

## Questions Page

### React Implementation (`src/pages/Questions.tsx`)

```typescript
// Filters
const [filters, setFilters] = useState({
  mainCategoryId: '',
  subCategoryId: '',
  points: '',
  status: '',
  search: '',
});

// Load with filters
const questionsData = await questionsApi.getAll({
  mainCategoryId: filters.mainCategoryId || undefined,
  subCategoryId: filters.subCategoryId || undefined,
  points: filters.points ? parseInt(filters.points) : undefined,
  status: filters.status || undefined,
  search: filters.search || undefined,
});

// Create question
await questionsApi.create({
  sub_category_id: formData.sub_category_id,
  question_text_ar: formData.question_text_ar,
  answer_text_ar: formData.answer_text_ar,
  question_media_url: formData.question_media_url,
  answer_media_url: formData.answer_media_url,
  points: formData.points, // 200, 400, or 600
  status: formData.status,
});
```

### Flutter Implementation (TODO)

```dart
// Filters
String? _mainCategoryFilter;
String? _subCategoryFilter;
int? _pointsFilter;
String? _statusFilter;

// Load with filters
final questions = await _service.getQuestions(
  subCategoryId: _subCategoryFilter,
  points: _pointsFilter,
  status: _statusFilter,
).first;

// Create question
try {
  await _service.addQuestion(SeenjeemQuestionModel(
    id: '',
    subCategoryId: _subCategoryIdController.text,
    questionTextAr: _questionController.text,
    answerTextAr: _answerController.text,
    questionMediaUrl: _questionMediaUrl,
    answerMediaUrl: _answerMediaUrl,
    points: _selectedPoints, // 200, 400, or 600
    status: _selectedStatus,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ));
} catch (e) {
  // Handle duplicate points error
  showDialog(...);
}
```

## Media Upload

### React (`src/lib/mediaUtils.ts`)

```typescript
async uploadFile(file: File, folder: string) {
  const fileName = `${Date.now()}_${file.name}`;
  const filePath = `${folder}/${fileName}`;

  const { data, error } = await supabase.storage
    .from('seenjeem-media')
    .upload(filePath, file);

  return { url: publicUrl, path: filePath };
}
```

### Flutter (`lib/services/seenjeem_service.dart`)

```dart
Future<String> uploadMedia(
  Uint8List fileBytes,
  String fileName,
  String folder
) async {
  final ref = _storage.ref().child('$folder/$fileName');
  final uploadTask = await ref.putData(fileBytes);
  final downloadUrl = await uploadTask.ref.getDownloadURL();
  return downloadUrl;
}
```

## Excel Import/Export

### React (`src/lib/excelUtils.ts`)

```typescript
// Export
exportToExcel(exportData, 'main_categories.xlsx', 'Main Categories');

// Import
const data = await parseExcelFile(file);
for (const row of data) {
  await mainCategoriesApi.create({
    name_ar: row.name_ar,
    display_order: row.display_order,
    is_active: row.is_active === 'true',
  });
}
```

### Flutter (`lib/services/excel_service.dart`)

```dart
// Export
void exportToExcel(List<Map<String, dynamic>> data, String filename);

// Import
Future<List<T>> importFromExcel<T>(
  File file,
  T Function(Map<String, dynamic>) fromMap
) async {
  final bytes = file.readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);
  final sheet = excel.tables[excel.tables.keys.first];

  List<T> items = [];
  for (var row in sheet!.rows.skip(1)) {
    items.add(fromMap(rowToMap(row)));
  }
  return items;
}
```

## Form Validation

### React

```typescript
// Inline validation
if (!formData.media_url) {
  alert('Sub-category media is required');
  return;
}

// Backend validation
try {
  await questionsApi.create(formData);
} catch (error) {
  alert(error.message); // "Question with this points value already exists"
}
```

### Flutter

```dart
// Form validation
if (_formKey.currentState!.validate()) {
  // Form is valid
}

validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Please enter name';
  }
  return null;
}

// Backend validation
try {
  await _service.addQuestion(question);
} catch (e) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Error'),
      content: Text(e.toString()),
    ),
  );
}
```

## Status Management

### React

```typescript
type Status = 'active' | 'disabled' | 'draft';

const handleToggleStatus = async (item: Question) => {
  const newStatus = item.status === 'active' ? 'disabled' : 'active';
  await questionsApi.update(item.id, { status: newStatus });
};
```

### Flutter

```dart
enum Status { active, disabled, draft }

Future<void> _toggleStatus(SeenjeemQuestionModel question) async {
  final newStatus = question.status == 'active' ? 'disabled' : 'active';
  final updated = SeenjeemQuestionModel(
    ...question,
    status: newStatus,
  );
  await _service.updateQuestion(question.id, updated);
}
```

## Points System

### React

```typescript
// Points are restricted to specific values
type Points = 200 | 400 | 600;

// Dropdown
<select value={formData.points}>
  <option value="200">200 Points</option>
  <option value="400">400 Points</option>
  <option value="600">600 Points</option>
</select>

// Validation
if (![200, 400, 600].includes(points)) {
  throw new Error('Invalid points value');
}
```

### Flutter

```dart
// Points are restricted to specific values
enum QuestionPoints { points200, points400, points600 }

// Or just use int with validation
int _points = 200;

// Dropdown
DropdownButton<int>(
  value: _points,
  items: [200, 400, 600].map((points) {
    return DropdownMenuItem<int>(
      value: points,
      child: Text('$points Points'),
    );
  }).toList(),
  onChanged: (value) {
    setState(() => _points = value!);
  },
)

// Validation in service
if (![200, 400, 600].contains(question.points)) {
  throw Exception('Invalid points value');
}
```

## Search & Filter

### React

```typescript
// Filter state
const [filters, setFilters] = useState({
  search: '',
  mainCategoryId: '',
  subCategoryId: '',
  points: '',
  status: '',
});

// Apply filters
const filtered = questions.filter(q => {
  if (filters.search && !q.question_text_ar.includes(filters.search)) {
    return false;
  }
  if (filters.points && q.points !== parseInt(filters.points)) {
    return false;
  }
  return true;
});
```

### Flutter

```dart
// Use Firestore queries for filtering
Stream<List<SeenjeemQuestionModel>> _getFilteredQuestions() {
  Query query = _db.collection('questions');

  if (_subCategoryFilter != null) {
    query = query.where('sub_category_id', isEqualTo: _subCategoryFilter);
  }

  if (_pointsFilter != null) {
    query = query.where('points', isEqualTo: _pointsFilter);
  }

  if (_statusFilter != null) {
    query = query.where('status', isEqualTo: _statusFilter);
  }

  return query.snapshots().map(...);
}

// For text search, filter in Dart after fetching
final filtered = questions.where((q) =>
  q.questionTextAr.contains(_searchQuery)
).toList();
```

## Key Differences

| Feature | React/Supabase | Flutter/Firebase |
|---------|---------------|------------------|
| Real-time updates | Supabase subscriptions | Firestore streams (`snapshots()`) |
| Storage | Supabase Storage | Firebase Storage |
| Auth | Supabase Auth | Firebase Auth |
| Queries | SQL-like | NoSQL queries with limitations |
| Relations | Foreign keys enforced | Manual relationship management |
| File upload | Direct from browser | Platform-specific (web/mobile) |

## Common Patterns

### Loading State

**React:**
```typescript
const [loading, setLoading] = useState(true);
```

**Flutter:**
```dart
bool _isLoading = true;

if (_isLoading) {
  return Center(child: CircularProgressIndicator());
}
```

### Error Handling

**React:**
```typescript
try {
  await api.create(data);
} catch (error) {
  alert(error.message);
}
```

**Flutter:**
```dart
try {
  await service.add(data);
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.toString())),
  );
}
```

### Form State

**React:**
```typescript
const [formData, setFormData] = useState({
  name: '',
  value: 0,
});

<input
  value={formData.name}
  onChange={(e) => setFormData({...formData, name: e.target.value})}
/>
```

**Flutter:**
```dart
final _nameController = TextEditingController();

TextField(
  controller: _nameController,
)

// Don't forget to dispose
@override
void dispose() {
  _nameController.dispose();
  super.dispose();
}
```
