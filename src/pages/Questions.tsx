import { useEffect, useState, useRef } from 'react';
import { Plus, Edit2, Eye, Power, Search, Filter, Upload, Download, Image as ImageIcon, Trash2, AlertCircle } from 'lucide-react';
import { questionsApi, mainCategoriesApi, subCategoriesApi, type Question, type MainCategory, type SubCategory } from '../lib/api';
import { mediaUtils } from '../lib/mediaUtils';
import Modal from '../components/Modal';
import Badge from '../components/Badge';
import { parseExcelFile, downloadExcelTemplate } from '../lib/excelUtils';

export default function Questions() {
  const [questions, setQuestions] = useState<Question[]>([]);
  const [mainCategories, setMainCategories] = useState<MainCategory[]>([]);
  const [subCategories, setSubCategories] = useState<SubCategory[]>([]);
  const [filteredSubCategories, setFilteredSubCategories] = useState<SubCategory[]>([]);
  const [loading, setLoading] = useState(true);
  const [modalOpen, setModalOpen] = useState(false);
  const [viewModalOpen, setViewModalOpen] = useState(false);
  const [editingQuestion, setEditingQuestion] = useState<Question | null>(null);
  const [viewingQuestion, setViewingQuestion] = useState<Question | null>(null);
  const [uploading, setUploading] = useState(false);
  const [importing, setImporting] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const importInputRef = useRef<HTMLInputElement>(null);
  const [filters, setFilters] = useState({
    mainCategoryId: '',
    subCategoryId: '',
    points: '',
    status: '',
    search: '',
  });
  const [formData, setFormData] = useState({
    sub_category_id: '',
    question_text_ar: '',
    answer_text_ar: '',
    question_media_url: null as string | null,
    answer_media_url: null as string | null,
    points: 200 as 200 | 400 | 600,
    status: 'active' as 'active' | 'disabled' | 'draft',
  });

  useEffect(() => {
    loadData();
  }, [filters]);

  useEffect(() => {
    if (filters.mainCategoryId) {
      const filtered = subCategories.filter(sub => sub.main_category_id === filters.mainCategoryId);
      setFilteredSubCategories(filtered);
    } else {
      setFilteredSubCategories(subCategories);
    }
  }, [filters.mainCategoryId, subCategories]);

  const loadData = async () => {
    try {
      const [questionsData, mainCategoriesData, subCategoriesData] = await Promise.all([
        questionsApi.getAll({
          mainCategoryId: filters.mainCategoryId || undefined,
          subCategoryId: filters.subCategoryId || undefined,
          points: filters.points ? parseInt(filters.points) : undefined,
          status: filters.status || undefined,
          search: filters.search || undefined,
        }),
        mainCategoriesApi.getAll(),
        subCategoriesApi.getAll(),
      ]);
      setQuestions(questionsData);
      setMainCategories(mainCategoriesData);
      setSubCategories(subCategoriesData);
    } catch (error) {
      console.error('Error loading data:', error);
      alert('Error loading data');
    } finally {
      setLoading(false);
    }
  };

  const handleOpenModal = (question?: Question) => {
    if (question) {
      setEditingQuestion(question);
      setFormData({
        sub_category_id: question.sub_category_id,
        question_text_ar: question.question_text_ar,
        answer_text_ar: question.answer_text_ar,
        question_media_url: question.question_media_url,
        answer_media_url: question.answer_media_url,
        points: question.points,
        status: question.status,
      });
    } else {
      setEditingQuestion(null);
      setFormData({
        sub_category_id: filters.subCategoryId || '',
        question_text_ar: '',
        answer_text_ar: '',
        question_media_url: null,
        answer_media_url: null,
        points: 200,
        status: 'active',
      });
    }
    setModalOpen(true);
  };

  const handleCloseModal = () => {
    setModalOpen(false);
    setEditingQuestion(null);
  };

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>, field: 'question_media_url' | 'answer_media_url') => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!mediaUtils.isValidMediaFile(file)) {
      alert('Please upload a valid media file (image or video)');
      return;
    }

    setUploading(true);
    try {
      const result = await mediaUtils.uploadFile(file, `questions/${field}`);
      setFormData({ ...formData, [field]: result.url });
    } catch (error) {
      console.error('Error uploading file:', error);
      alert('Error uploading file. Please try again.');
    } finally {
      setUploading(false);
    }
  };

  const handleRemoveMedia = async (field: 'question_media_url' | 'answer_media_url') => {
    const url = formData[field];
    if (!url) return;

    try {
      const path = mediaUtils.getPathFromUrl(url);
      if (path) {
        await mediaUtils.deleteFile(path);
      }
      setFormData({ ...formData, [field]: null });
    } catch (error) {
      console.error('Error removing media:', error);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (editingQuestion) {
        await questionsApi.update(editingQuestion.id, formData);
      } else {
        await questionsApi.create(formData);
      }
      await loadData();
      handleCloseModal();
    } catch (error: any) {
      console.error('Error saving question:', error);
      alert(error.message || 'Error saving question. Please try again.');
    }
  };

  const handleToggleStatus = async (question: Question) => {
    try {
      const newStatus = question.status === 'active' ? 'disabled' : 'active';
      await questionsApi.update(question.id, { status: newStatus });
      await loadData();
    } catch (error) {
      console.error('Error toggling question status:', error);
    }
  };

  const handleViewQuestion = (question: Question) => {
    setViewingQuestion(question);
    setViewModalOpen(true);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  const getQuestionCountForSubCategory = (subCategoryId: string): { total: number; byPoints: Record<number, number> } => {
    const subCategoryQuestions = questions.filter(q => q.sub_category_id === subCategoryId);
    const byPoints: Record<number, number> = { 200: 0, 400: 0, 600: 0 };
    subCategoryQuestions.forEach(q => {
      byPoints[q.points] = (byPoints[q.points] || 0) + 1;
    });
    return { total: subCategoryQuestions.length, byPoints };
  };

  const handleImportExcel = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setImporting(true);
    try {
      const data = await parseExcelFile(file);
      let successCount = 0;
      let errorCount = 0;
      let skippedCount = 0;
      const errors: string[] = [];

      for (const row of data) {
        try {
          const mainCategory = mainCategories.find(cat => cat.name_ar === row.main_category_name_ar);
          if (!mainCategory) {
            errors.push(`Main category "${row.main_category_name_ar}" not found`);
            errorCount++;
            continue;
          }

          const subCategory = subCategories.find(
            cat => cat.main_category_id === mainCategory.id && cat.name_ar === row.sub_category_name_ar
          );
          if (!subCategory) {
            errors.push(`Sub category "${row.sub_category_name_ar}" not found in main category "${row.main_category_name_ar}"`);
            errorCount++;
            continue;
          }

          const points = parseInt(row.points);
          if (![200, 400, 600].includes(points)) {
            errors.push(`Invalid points value "${row.points}" for question. Must be 200, 400, or 600`);
            errorCount++;
            continue;
          }

          const existing = questions.find(
            q => q.sub_category_id === subCategory.id && q.points === points
          );
          if (existing) {
            skippedCount++;
            continue;
          }

          await questionsApi.create({
            sub_category_id: subCategory.id,
            question_text_ar: row.question_text_ar,
            answer_text_ar: row.answer_text_ar,
            question_media_url: row.question_media_url || null,
            answer_media_url: row.answer_media_url || null,
            points: points as 200 | 400 | 600,
            status: (row.status || 'active') as 'active' | 'disabled' | 'draft',
          });
          successCount++;
        } catch (error: any) {
          console.error('Error importing question:', error);
          errors.push(`Question error: ${error.message}`);
          errorCount++;
        }
      }

      await loadData();

      let message = `Import complete!\n\nCreated: ${successCount}\nSkipped: ${skippedCount}\nErrors: ${errorCount}`;
      if (errors.length > 0 && errors.length <= 5) {
        message += '\n\nErrors:\n' + errors.join('\n');
      } else if (errors.length > 5) {
        message += '\n\nShowing first 5 errors:\n' + errors.slice(0, 5).join('\n');
      }
      alert(message);
    } catch (error) {
      console.error('Error parsing Excel file:', error);
      alert('Error importing file. Please check the file format.');
    } finally {
      setImporting(false);
      if (importInputRef.current) {
        importInputRef.current.value = '';
      }
    }
  };

  const handleDownloadTemplate = () => {
    downloadExcelTemplate('questions');
  };

  const handleExport = () => {
    const exportData = questions.map(q => ({
      main_category_name_ar: q.sub_categories?.main_categories?.name_ar || '',
      sub_category_name_ar: q.sub_categories?.name_ar || '',
      points: q.points,
      question_text_ar: q.question_text_ar,
      answer_text_ar: q.answer_text_ar,
      question_media_url: q.question_media_url || '',
      answer_media_url: q.answer_media_url || '',
      status: q.status,
      created_at: formatDate(q.created_at),
    }));
    exportToExcel(exportData, 'questions.xlsx', 'Questions');
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Loading questions...</div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Questions</h1>
          <p className="text-gray-600 mt-1">Manage quiz questions for SeenJeem game board</p>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={handleDownloadTemplate}
            className="flex items-center gap-2 px-4 py-3 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors font-medium"
          >
            <Download className="w-5 h-5" />
            Template
          </button>
          <button
            onClick={handleExport}
            className="flex items-center gap-2 px-4 py-3 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors font-medium"
          >
            <Download className="w-5 h-5" />
            Export
          </button>
          <label className="flex items-center gap-2 px-4 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors font-medium cursor-pointer">
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
          <button
            onClick={() => handleOpenModal()}
            className="flex items-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-medium shadow-sm"
          >
            <Plus className="w-5 h-5" />
            Add Question
          </button>
        </div>
      </div>

      <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 flex items-start gap-3">
        <AlertCircle className="w-5 h-5 text-yellow-600 flex-shrink-0 mt-0.5" />
        <div className="text-sm text-yellow-800">
          <strong>Important:</strong> Each sub-category must have exactly ONE question for each point value (200, 400, 600). The system prevents duplicate point values per sub-category.
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-4">
        <div className="flex items-center gap-3 mb-4">
          <Filter className="w-5 h-5 text-gray-400" />
          <span className="text-sm font-semibold text-gray-700">Filters</span>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
          <div>
            <select
              value={filters.mainCategoryId}
              onChange={(e) => setFilters({ ...filters, mainCategoryId: e.target.value, subCategoryId: '' })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm"
            >
              <option value="">All Main Categories</option>
              {mainCategories.map((cat) => (
                <option key={cat.id} value={cat.id}>
                  {cat.name_ar}
                </option>
              ))}
            </select>
          </div>
          <div>
            <select
              value={filters.subCategoryId}
              onChange={(e) => setFilters({ ...filters, subCategoryId: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm"
              disabled={!filters.mainCategoryId}
            >
              <option value="">All Sub Categories</option>
              {filteredSubCategories.map((cat) => (
                <option key={cat.id} value={cat.id}>
                  {cat.name_ar}
                </option>
              ))}
            </select>
          </div>
          <div>
            <select
              value={filters.points}
              onChange={(e) => setFilters({ ...filters, points: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm"
            >
              <option value="">All Points</option>
              <option value="200">200 Points</option>
              <option value="400">400 Points</option>
              <option value="600">600 Points</option>
            </select>
          </div>
          <div>
            <select
              value={filters.status}
              onChange={(e) => setFilters({ ...filters, status: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm"
            >
              <option value="">All Status</option>
              <option value="active">Active</option>
              <option value="disabled">Disabled</option>
              <option value="draft">Draft</option>
            </select>
          </div>
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              placeholder="Search questions..."
              value={filters.search}
              onChange={(e) => setFilters({ ...filters, search: e.target.value })}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm"
              dir="rtl"
            />
          </div>
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="text-left px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Question
                </th>
                <th className="text-left px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Sub Category
                </th>
                <th className="text-left px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Points
                </th>
                <th className="text-left px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Media
                </th>
                <th className="text-left px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Status
                </th>
                <th className="text-right px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {questions.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-gray-500">
                    No questions found. Create your first question or adjust filters.
                  </td>
                </tr>
              ) : (
                questions.map((question) => (
                  <tr key={question.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4">
                      <p className="text-sm text-gray-900 font-medium line-clamp-2 max-w-md" dir="rtl">
                        {question.question_text_ar}
                      </p>
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-sm text-gray-700" dir="rtl">
                        {question.sub_categories?.name_ar || 'N/A'}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <Badge variant="info">{question.points}</Badge>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2">
                        {question.question_media_url && (
                          <div className="w-8 h-8 bg-blue-100 rounded flex items-center justify-center" title="Question has media">
                            <ImageIcon className="w-4 h-4 text-blue-600" />
                          </div>
                        )}
                        {question.answer_media_url && (
                          <div className="w-8 h-8 bg-green-100 rounded flex items-center justify-center" title="Answer has media">
                            <ImageIcon className="w-4 h-4 text-green-600" />
                          </div>
                        )}
                        {!question.question_media_url && !question.answer_media_url && (
                          <span className="text-sm text-gray-400">None</span>
                        )}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <Badge variant={question.status === 'active' ? 'success' : question.status === 'draft' ? 'default' : 'error'}>
                        {question.status.charAt(0).toUpperCase() + question.status.slice(1)}
                      </Badge>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => handleViewQuestion(question)}
                          className="p-2 text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
                          title="View"
                        >
                          <Eye className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleOpenModal(question)}
                          className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                          title="Edit"
                        >
                          <Edit2 className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleToggleStatus(question)}
                          className={`p-2 rounded-lg transition-colors ${
                            question.status === 'active'
                              ? 'text-red-600 hover:bg-red-50'
                              : 'text-green-600 hover:bg-green-50'
                          }`}
                          title={question.status === 'active' ? 'Disable' : 'Enable'}
                        >
                          <Power className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <Modal
        isOpen={modalOpen}
        onClose={handleCloseModal}
        title={editingQuestion ? 'Edit Question' : 'Add Question'}
        size="lg"
      >
        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Main Category *
              </label>
              <select
                value={formData.sub_category_id ? subCategories.find(s => s.id === formData.sub_category_id)?.main_category_id || '' : ''}
                onChange={(e) => {
                  const mainCatId = e.target.value;
                  setFormData({ ...formData, sub_category_id: '' });
                  setFilteredSubCategories(subCategories.filter(sub => sub.main_category_id === mainCatId));
                }}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                required={!formData.sub_category_id}
              >
                <option value="">Select Main Category</option>
                {mainCategories.map((cat) => (
                  <option key={cat.id} value={cat.id}>
                    {cat.name_ar}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Sub Category *
              </label>
              <select
                value={formData.sub_category_id}
                onChange={(e) => setFormData({ ...formData, sub_category_id: e.target.value })}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                required
              >
                <option value="">Select Sub Category</option>
                {filteredSubCategories.map((cat) => (
                  <option key={cat.id} value={cat.id}>
                    {cat.name_ar}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Points *
              </label>
              <select
                value={formData.points}
                onChange={(e) => setFormData({ ...formData, points: parseInt(e.target.value) as 200 | 400 | 600 })}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                required
              >
                <option value="200">200 Points</option>
                <option value="400">400 Points</option>
                <option value="600">600 Points</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Status
              </label>
              <select
                value={formData.status}
                onChange={(e) => setFormData({ ...formData, status: e.target.value as 'active' | 'disabled' | 'draft' })}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="active">Active</option>
                <option value="disabled">Disabled</option>
                <option value="draft">Draft</option>
              </select>
            </div>
          </div>

          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-2">
              Question (Arabic) *
            </label>
            <textarea
              value={formData.question_text_ar}
              onChange={(e) => setFormData({ ...formData, question_text_ar: e.target.value })}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              rows={3}
              placeholder="Enter your question in Arabic"
              required
              dir="rtl"
            />
          </div>

          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-2">
              Question Media (Optional)
            </label>
            <div className="space-y-3">
              {formData.question_media_url && (
                <div className="relative inline-block">
                  {mediaUtils.getMediaType({ type: formData.question_media_url.includes('video') ? 'video/mp4' : 'image/jpeg' } as File) === 'video' ? (
                    <video src={formData.question_media_url} className="w-32 h-32 object-cover rounded-lg" controls />
                  ) : (
                    <img src={formData.question_media_url} alt="Question media" className="w-32 h-32 object-cover rounded-lg" />
                  )}
                  <button
                    type="button"
                    onClick={() => handleRemoveMedia('question_media_url')}
                    className="absolute -top-2 -right-2 p-1 bg-red-500 text-white rounded-full hover:bg-red-600"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              )}
              <label className="flex items-center gap-2 px-4 py-3 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors font-medium cursor-pointer w-fit">
                <Upload className="w-5 h-5" />
                {uploading ? 'Uploading...' : 'Upload Media'}
                <input
                  type="file"
                  accept="image/*,video/*"
                  onChange={(e) => handleFileUpload(e, 'question_media_url')}
                  className="hidden"
                  disabled={uploading}
                />
              </label>
            </div>
          </div>

          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-2">
              Answer (Arabic) *
            </label>
            <textarea
              value={formData.answer_text_ar}
              onChange={(e) => setFormData({ ...formData, answer_text_ar: e.target.value })}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              rows={3}
              placeholder="Enter your answer in Arabic"
              required
              dir="rtl"
            />
          </div>

          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-2">
              Answer Media (Optional)
            </label>
            <div className="space-y-3">
              {formData.answer_media_url && (
                <div className="relative inline-block">
                  {mediaUtils.getMediaType({ type: formData.answer_media_url.includes('video') ? 'video/mp4' : 'image/jpeg' } as File) === 'video' ? (
                    <video src={formData.answer_media_url} className="w-32 h-32 object-cover rounded-lg" controls />
                  ) : (
                    <img src={formData.answer_media_url} alt="Answer media" className="w-32 h-32 object-cover rounded-lg" />
                  )}
                  <button
                    type="button"
                    onClick={() => handleRemoveMedia('answer_media_url')}
                    className="absolute -top-2 -right-2 p-1 bg-red-500 text-white rounded-full hover:bg-red-600"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              )}
              <label className="flex items-center gap-2 px-4 py-3 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors font-medium cursor-pointer w-fit">
                <Upload className="w-5 h-5" />
                {uploading ? 'Uploading...' : 'Upload Media'}
                <input
                  type="file"
                  accept="image/*,video/*"
                  onChange={(e) => handleFileUpload(e, 'answer_media_url')}
                  className="hidden"
                  disabled={uploading}
                />
              </label>
            </div>
          </div>

          <div className="flex gap-3 pt-4">
            <button
              type="button"
              onClick={handleCloseModal}
              className="flex-1 px-6 py-3 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors font-medium"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="flex-1 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-medium"
              disabled={uploading}
            >
              {editingQuestion ? 'Update' : 'Create'}
            </button>
          </div>
        </form>
      </Modal>

      <Modal
        isOpen={viewModalOpen}
        onClose={() => setViewModalOpen(false)}
        title="Question Details"
        size="md"
      >
        {viewingQuestion && (
          <div className="space-y-6">
            <div>
              <h3 className="text-sm font-semibold text-gray-700 mb-2">Sub Category</h3>
              <p className="text-gray-900" dir="rtl">{viewingQuestion.sub_categories?.name_ar || 'N/A'}</p>
            </div>

            <div>
              <h3 className="text-sm font-semibold text-gray-700 mb-2">Points</h3>
              <Badge variant="info">{viewingQuestion.points}</Badge>
            </div>

            <div>
              <h3 className="text-sm font-semibold text-gray-700 mb-2">Question</h3>
              <p className="text-gray-900 whitespace-pre-wrap" dir="rtl">{viewingQuestion.question_text_ar}</p>
              {viewingQuestion.question_media_url && (
                <div className="mt-3">
                  {viewingQuestion.question_media_url.includes('video') ? (
                    <video src={viewingQuestion.question_media_url} className="max-w-full h-auto rounded-lg" controls />
                  ) : (
                    <img src={viewingQuestion.question_media_url} alt="Question" className="max-w-full h-auto rounded-lg" />
                  )}
                </div>
              )}
            </div>

            <div>
              <h3 className="text-sm font-semibold text-gray-700 mb-2">Answer</h3>
              <p className="text-gray-900 whitespace-pre-wrap bg-green-50 p-3 rounded-lg" dir="rtl">{viewingQuestion.answer_text_ar}</p>
              {viewingQuestion.answer_media_url && (
                <div className="mt-3">
                  {viewingQuestion.answer_media_url.includes('video') ? (
                    <video src={viewingQuestion.answer_media_url} className="max-w-full h-auto rounded-lg" controls />
                  ) : (
                    <img src={viewingQuestion.answer_media_url} alt="Answer" className="max-w-full h-auto rounded-lg" />
                  )}
                </div>
              )}
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <h3 className="text-sm font-semibold text-gray-700 mb-2">Status</h3>
                <Badge variant={viewingQuestion.status === 'active' ? 'success' : viewingQuestion.status === 'draft' ? 'default' : 'error'}>
                  {viewingQuestion.status.charAt(0).toUpperCase() + viewingQuestion.status.slice(1)}
                </Badge>
              </div>
              <div>
                <h3 className="text-sm font-semibold text-gray-700 mb-2">Created At</h3>
                <p className="text-gray-900 text-sm">{formatDate(viewingQuestion.created_at)}</p>
              </div>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
