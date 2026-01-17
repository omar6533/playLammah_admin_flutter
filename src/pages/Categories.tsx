import { useEffect, useState, useRef } from 'react';
import { Plus, Edit2, Power, Upload, Download, Image as ImageIcon, Trash2, Folder, FolderOpen } from 'lucide-react';
import { mainCategoriesApi, subCategoriesApi, type MainCategory, type SubCategory } from '../lib/api';
import { mediaUtils } from '../lib/mediaUtils';
import { parseExcelFile, downloadExcelTemplate, exportToExcel } from '../lib/excelUtils';
import Modal from '../components/Modal';
import Badge from '../components/Badge';

type TabType = 'main' | 'sub';

export default function Categories() {
  const [activeTab, setActiveTab] = useState<TabType>('main');
  const [mainCategories, setMainCategories] = useState<MainCategory[]>([]);
  const [subCategories, setSubCategories] = useState<SubCategory[]>([]);
  const [loading, setLoading] = useState(true);
  const [modalOpen, setModalOpen] = useState(false);
  const [editingItem, setEditingItem] = useState<MainCategory | SubCategory | null>(null);
  const [selectedMainCategory, setSelectedMainCategory] = useState<string>('');
  const [uploading, setUploading] = useState(false);
  const [importing, setImporting] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const importInputRef = useRef<HTMLInputElement>(null);
  const [mainFormData, setMainFormData] = useState({
    name_ar: '',
    media_url: null as string | null,
    display_order: 0,
    is_active: true,
    status: 'active' as 'active' | 'disabled',
  });
  const [subFormData, setSubFormData] = useState({
    main_category_id: '',
    name_ar: '',
    media_url: '',
    display_order: 0,
    is_active: true,
  });

  useEffect(() => {
    loadData();
  }, [selectedMainCategory]);

  const loadData = async () => {
    try {
      const [mainData, subData] = await Promise.all([
        mainCategoriesApi.getAll(),
        subCategoriesApi.getAll(selectedMainCategory || undefined),
      ]);
      setMainCategories(mainData);
      setSubCategories(subData);
    } catch (error) {
      console.error('Error loading categories:', error);
      alert('Error loading categories');
    } finally {
      setLoading(false);
    }
  };

  const handleOpenModal = (item?: MainCategory | SubCategory, type?: TabType) => {
    const modalType = type || activeTab;

    if (item) {
      setEditingItem(item);
      if (modalType === 'main') {
        const mainItem = item as MainCategory;
        setMainFormData({
          name_ar: mainItem.name_ar,
          media_url: mainItem.media_url,
          display_order: mainItem.display_order,
          is_active: mainItem.is_active,
          status: mainItem.status,
        });
      } else {
        const subItem = item as SubCategory;
        setSubFormData({
          main_category_id: subItem.main_category_id,
          name_ar: subItem.name_ar,
          media_url: subItem.media_url,
          display_order: subItem.display_order,
          is_active: subItem.is_active,
        });
      }
    } else {
      setEditingItem(null);
      if (modalType === 'main') {
        setMainFormData({
          name_ar: '',
          media_url: null,
          display_order: mainCategories.length,
          is_active: true,
          status: 'active',
        });
      } else {
        setSubFormData({
          main_category_id: selectedMainCategory || (mainCategories[0]?.id || ''),
          name_ar: '',
          media_url: '',
          display_order: subCategories.length,
          is_active: true,
        });
      }
    }
    setModalOpen(true);
  };

  const handleCloseModal = () => {
    setModalOpen(false);
    setEditingItem(null);
  };

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>, isMain: boolean) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!mediaUtils.isValidMediaFile(file)) {
      alert('Please upload a valid image file (JPEG, PNG, GIF, WEBP)');
      return;
    }

    setUploading(true);
    try {
      const result = await mediaUtils.uploadFile(file, isMain ? 'main-categories' : 'sub-categories');

      if (isMain) {
        setMainFormData({ ...mainFormData, media_url: result.url });
      } else {
        setSubFormData({ ...subFormData, media_url: result.url });
      }
    } catch (error) {
      console.error('Error uploading file:', error);
      alert('Error uploading file. Please try again.');
    } finally {
      setUploading(false);
    }
  };

  const handleRemoveMedia = async (url: string | null, isMain: boolean) => {
    if (!url) return;

    try {
      const path = mediaUtils.getPathFromUrl(url);
      if (path) {
        await mediaUtils.deleteFile(path);
      }

      if (isMain) {
        setMainFormData({ ...mainFormData, media_url: null });
      } else {
        setSubFormData({ ...subFormData, media_url: '' });
      }
    } catch (error) {
      console.error('Error removing media:', error);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (activeTab === 'main') {
        if (editingItem) {
          await mainCategoriesApi.update((editingItem as MainCategory).id, mainFormData);
        } else {
          await mainCategoriesApi.create(mainFormData);
        }
      } else {
        if (!subFormData.media_url) {
          alert('Sub-category media is required');
          return;
        }
        if (editingItem) {
          await subCategoriesApi.update((editingItem as SubCategory).id, subFormData);
        } else {
          await subCategoriesApi.create(subFormData);
        }
      }
      await loadData();
      handleCloseModal();
    } catch (error) {
      console.error('Error saving category:', error);
      alert('Error saving category. Please try again.');
    }
  };

  const handleToggleStatus = async (item: MainCategory | SubCategory, type: TabType) => {
    try {
      if (type === 'main') {
        const mainItem = item as MainCategory;
        await mainCategoriesApi.update(mainItem.id, {
          is_active: !mainItem.is_active,
          status: mainItem.is_active ? 'disabled' : 'active'
        });
      } else {
        const subItem = item as SubCategory;
        await subCategoriesApi.update(subItem.id, {
          is_active: !subItem.is_active
        });
      }
      await loadData();
    } catch (error) {
      console.error('Error toggling status:', error);
      alert('Error updating status.');
    }
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
          if (activeTab === 'main') {
            const existing = mainCategories.find(cat => cat.name_ar === row.name_ar);
            if (existing) {
              skippedCount++;
              continue;
            }

            await mainCategoriesApi.create({
              name_ar: row.name_ar,
              display_order: row.display_order || mainCategories.length,
              is_active: row.is_active === 'true' || row.is_active === true,
              status: (row.is_active === 'true' || row.is_active === true) ? 'active' : 'disabled',
              media_url: row.media_url || null,
            });
            successCount++;
          } else {
            const mainCategory = mainCategories.find(cat => cat.name_ar === row.main_category_name_ar);
            if (!mainCategory) {
              errors.push(`Main category "${row.main_category_name_ar}" not found for sub-category "${row.name_ar}"`);
              errorCount++;
              continue;
            }

            const existing = subCategories.find(
              cat => cat.main_category_id === mainCategory.id && cat.name_ar === row.name_ar
            );
            if (existing) {
              skippedCount++;
              continue;
            }

            if (!row.media_url) {
              errors.push(`Media URL is required for sub-category "${row.name_ar}"`);
              errorCount++;
              continue;
            }

            await subCategoriesApi.create({
              main_category_id: mainCategory.id,
              name_ar: row.name_ar,
              display_order: row.display_order || 0,
              is_active: row.is_active === 'true' || row.is_active === true,
              media_url: row.media_url,
            });
            successCount++;
          }
        } catch (error: any) {
          console.error('Error importing row:', error);
          errors.push(`Row error: ${error.message}`);
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
    if (activeTab === 'main') {
      downloadExcelTemplate('main-categories');
    } else {
      downloadExcelTemplate('sub-categories');
    }
  };

  const handleExport = () => {
    if (activeTab === 'main') {
      const exportData = mainCategories.map(cat => ({
        name_ar: cat.name_ar,
        display_order: cat.display_order,
        is_active: cat.is_active ? 'true' : 'false',
        media_url: cat.media_url || '',
        created_at: formatDate(cat.created_at),
      }));
      exportToExcel(exportData, 'main_categories.xlsx', 'Main Categories');
    } else {
      const exportData = subCategories.map(cat => ({
        main_category_name_ar: cat.main_categories?.name_ar || '',
        name_ar: cat.name_ar,
        display_order: cat.display_order,
        is_active: cat.is_active ? 'true' : 'false',
        media_url: cat.media_url,
        created_at: formatDate(cat.created_at),
      }));
      exportToExcel(exportData, 'sub_categories.xlsx', 'Sub Categories');
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Loading categories...</div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Categories</h1>
          <p className="text-gray-600 mt-1">Manage main categories and sub categories for SeenJeem board</p>
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
            Add {activeTab === 'main' ? 'Main Category' : 'Sub Category'}
          </button>
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200">
        <div className="border-b border-gray-200">
          <div className="flex">
            <button
              onClick={() => setActiveTab('main')}
              className={`flex items-center gap-2 px-6 py-4 font-semibold transition-colors ${
                activeTab === 'main'
                  ? 'text-blue-600 border-b-2 border-blue-600'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              <Folder className="w-5 h-5" />
              Main Categories ({mainCategories.length})
            </button>
            <button
              onClick={() => setActiveTab('sub')}
              className={`flex items-center gap-2 px-6 py-4 font-semibold transition-colors ${
                activeTab === 'sub'
                  ? 'text-blue-600 border-b-2 border-blue-600'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              <FolderOpen className="w-5 h-5" />
              Sub Categories ({subCategories.length})
            </button>
          </div>
        </div>

        {activeTab === 'sub' && (
          <div className="p-4 bg-gray-50 border-b border-gray-200">
            <label className="block text-sm font-semibold text-gray-700 mb-2">
              Filter by Main Category
            </label>
            <select
              value={selectedMainCategory}
              onChange={(e) => setSelectedMainCategory(e.target.value)}
              className="w-full max-w-md px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="">All Main Categories</option>
              {mainCategories.map((cat) => (
                <option key={cat.id} value={cat.id}>
                  {cat.name_ar}
                </option>
              ))}
            </select>
          </div>
        )}

        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="text-left px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Order
                </th>
                <th className="text-left px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Name (Arabic)
                </th>
                {activeTab === 'sub' && (
                  <th className="text-left px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                    Main Category
                  </th>
                )}
                <th className="text-left px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Media
                </th>
                <th className="text-left px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Status
                </th>
                <th className="text-left px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Created At
                </th>
                <th className="text-right px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {activeTab === 'main' ? (
                mainCategories.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-6 py-12 text-center text-gray-500">
                      No main categories yet. Create your first main category to get started.
                    </td>
                  </tr>
                ) : (
                  mainCategories.map((category) => (
                    <tr key={category.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-sm font-medium text-gray-900">
                        {category.display_order}
                      </td>
                      <td className="px-6 py-4">
                        <p className="text-sm font-medium text-gray-900">{category.name_ar}</p>
                      </td>
                      <td className="px-6 py-4">
                        {category.media_url ? (
                          <img
                            src={category.media_url}
                            alt={category.name_ar}
                            className="w-12 h-12 object-cover rounded"
                          />
                        ) : (
                          <div className="w-12 h-12 bg-gray-200 rounded flex items-center justify-center">
                            <ImageIcon className="w-6 h-6 text-gray-400" />
                          </div>
                        )}
                      </td>
                      <td className="px-6 py-4">
                        <Badge variant={category.is_active ? 'success' : 'error'}>
                          {category.is_active ? 'Active' : 'Disabled'}
                        </Badge>
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-600">
                        {formatDate(category.created_at)}
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center justify-end gap-2">
                          <button
                            onClick={() => handleOpenModal(category, 'main')}
                            className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                            title="Edit"
                          >
                            <Edit2 className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => handleToggleStatus(category, 'main')}
                            className={`p-2 rounded-lg transition-colors ${
                              category.is_active
                                ? 'text-red-600 hover:bg-red-50'
                                : 'text-green-600 hover:bg-green-50'
                            }`}
                            title={category.is_active ? 'Disable' : 'Enable'}
                          >
                            <Power className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                )
              ) : (
                subCategories.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="px-6 py-12 text-center text-gray-500">
                      No sub categories yet. Create your first sub category to get started.
                    </td>
                  </tr>
                ) : (
                  subCategories.map((category) => (
                    <tr key={category.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-sm font-medium text-gray-900">
                        {category.display_order}
                      </td>
                      <td className="px-6 py-4">
                        <p className="text-sm font-medium text-gray-900">{category.name_ar}</p>
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-700">
                        {category.main_categories?.name_ar || 'N/A'}
                      </td>
                      <td className="px-6 py-4">
                        {category.media_url ? (
                          <img
                            src={category.media_url}
                            alt={category.name_ar}
                            className="w-12 h-12 object-cover rounded"
                          />
                        ) : (
                          <div className="w-12 h-12 bg-gray-200 rounded flex items-center justify-center">
                            <ImageIcon className="w-6 h-6 text-gray-400" />
                          </div>
                        )}
                      </td>
                      <td className="px-6 py-4">
                        <Badge variant={category.is_active ? 'success' : 'error'}>
                          {category.is_active ? 'Active' : 'Disabled'}
                        </Badge>
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-600">
                        {formatDate(category.created_at)}
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center justify-end gap-2">
                          <button
                            onClick={() => handleOpenModal(category, 'sub')}
                            className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                            title="Edit"
                          >
                            <Edit2 className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => handleToggleStatus(category, 'sub')}
                            className={`p-2 rounded-lg transition-colors ${
                              category.is_active
                                ? 'text-red-600 hover:bg-red-50'
                                : 'text-green-600 hover:bg-green-50'
                            }`}
                            title={category.is_active ? 'Disable' : 'Enable'}
                          >
                            <Power className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                )
              )}
            </tbody>
          </table>
        </div>
      </div>

      <Modal
        isOpen={modalOpen}
        onClose={handleCloseModal}
        title={editingItem ? `Edit ${activeTab === 'main' ? 'Main' : 'Sub'} Category` : `Add ${activeTab === 'main' ? 'Main' : 'Sub'} Category`}
        size="md"
      >
        <form onSubmit={handleSubmit} className="space-y-6">
          {activeTab === 'sub' && (
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Main Category *
              </label>
              <select
                value={subFormData.main_category_id}
                onChange={(e) => setSubFormData({ ...subFormData, main_category_id: e.target.value })}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                required
              >
                <option value="">Select Main Category</option>
                {mainCategories.map((cat) => (
                  <option key={cat.id} value={cat.id}>
                    {cat.name_ar}
                  </option>
                ))}
              </select>
            </div>
          )}

          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-2">
              Name (Arabic) *
            </label>
            <input
              type="text"
              value={activeTab === 'main' ? mainFormData.name_ar : subFormData.name_ar}
              onChange={(e) => {
                if (activeTab === 'main') {
                  setMainFormData({ ...mainFormData, name_ar: e.target.value });
                } else {
                  setSubFormData({ ...subFormData, name_ar: e.target.value });
                }
              }}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Enter category name in Arabic"
              required
              dir="rtl"
            />
          </div>

          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-2">
              Display Order *
            </label>
            <input
              type="number"
              value={activeTab === 'main' ? mainFormData.display_order : subFormData.display_order}
              onChange={(e) => {
                const value = parseInt(e.target.value);
                if (activeTab === 'main') {
                  setMainFormData({ ...mainFormData, display_order: value });
                } else {
                  setSubFormData({ ...subFormData, display_order: value });
                }
              }}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              min="0"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-2">
              Media (Image) {activeTab === 'sub' && '*'}
            </label>
            <div className="space-y-3">
              {((activeTab === 'main' && mainFormData.media_url) || (activeTab === 'sub' && subFormData.media_url)) && (
                <div className="relative inline-block">
                  <img
                    src={activeTab === 'main' ? mainFormData.media_url! : subFormData.media_url}
                    alt="Category media"
                    className="w-32 h-32 object-cover rounded-lg"
                  />
                  <button
                    type="button"
                    onClick={() => handleRemoveMedia(
                      activeTab === 'main' ? mainFormData.media_url : subFormData.media_url,
                      activeTab === 'main'
                    )}
                    className="absolute -top-2 -right-2 p-1 bg-red-500 text-white rounded-full hover:bg-red-600"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              )}
              <label className="flex items-center gap-2 px-4 py-3 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors font-medium cursor-pointer w-fit">
                <Upload className="w-5 h-5" />
                {uploading ? 'Uploading...' : 'Upload Image'}
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/*"
                  onChange={(e) => handleFileUpload(e, activeTab === 'main')}
                  className="hidden"
                  disabled={uploading}
                />
              </label>
              <p className="text-sm text-gray-500">
                {activeTab === 'main'
                  ? 'Optional: Upload a banner image for this main category'
                  : 'Required: Upload an icon/image for this sub category (shown on game board)'}
              </p>
            </div>
          </div>

          <div className="flex items-center">
            <input
              type="checkbox"
              id="is_active"
              checked={activeTab === 'main' ? mainFormData.is_active : subFormData.is_active}
              onChange={(e) => {
                if (activeTab === 'main') {
                  setMainFormData({
                    ...mainFormData,
                    is_active: e.target.checked,
                    status: e.target.checked ? 'active' : 'disabled'
                  });
                } else {
                  setSubFormData({ ...subFormData, is_active: e.target.checked });
                }
              }}
              className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
            />
            <label htmlFor="is_active" className="ml-2 text-sm font-semibold text-gray-700">
              Active
            </label>
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
              {editingItem ? 'Update' : 'Create'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
