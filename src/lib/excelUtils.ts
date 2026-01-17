import * as XLSX from 'xlsx';

export const parseExcelFile = (file: File): Promise<any[]> => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = (e) => {
      try {
        const data = e.target?.result;
        const workbook = XLSX.read(data, { type: 'binary' });
        const sheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[sheetName];
        const jsonData = XLSX.utils.sheet_to_json(worksheet);
        resolve(jsonData);
      } catch (error) {
        reject(error);
      }
    };

    reader.onerror = (error) => {
      reject(error);
    };

    reader.readAsBinaryString(file);
  });
};

export const downloadExcelTemplate = (type: 'main-categories' | 'sub-categories' | 'questions') => {
  let data: any[] = [];
  let filename = '';

  if (type === 'main-categories') {
    data = [
      {
        name_ar: 'الفئة الرئيسية 1',
        display_order: 0,
        is_active: 'true',
        media_url: ''
      },
      {
        name_ar: 'الفئة الرئيسية 2',
        display_order: 1,
        is_active: 'true',
        media_url: ''
      },
    ];
    filename = 'main_categories_template.xlsx';
  } else if (type === 'sub-categories') {
    data = [
      {
        main_category_name_ar: 'الفئة الرئيسية 1',
        name_ar: 'الفئة الفرعية 1',
        display_order: 0,
        is_active: 'true',
        media_url: 'https://example.com/image.jpg'
      },
      {
        main_category_name_ar: 'الفئة الرئيسية 1',
        name_ar: 'الفئة الفرعية 2',
        display_order: 1,
        is_active: 'true',
        media_url: 'https://example.com/image2.jpg'
      },
    ];
    filename = 'sub_categories_template.xlsx';
  } else if (type === 'questions') {
    data = [
      {
        main_category_name_ar: 'الفئة الرئيسية 1',
        sub_category_name_ar: 'الفئة الفرعية 1',
        points: 200,
        question_text_ar: 'ما هي عاصمة السعودية؟',
        answer_text_ar: 'الرياض',
        question_media_url: '',
        answer_media_url: '',
        status: 'active'
      },
      {
        main_category_name_ar: 'الفئة الرئيسية 1',
        sub_category_name_ar: 'الفئة الفرعية 1',
        points: 400,
        question_text_ar: 'متى تأسست المملكة العربية السعودية؟',
        answer_text_ar: '1932م',
        question_media_url: '',
        answer_media_url: '',
        status: 'active'
      },
      {
        main_category_name_ar: 'الفئة الرئيسية 1',
        sub_category_name_ar: 'الفئة الفرعية 1',
        points: 600,
        question_text_ar: 'من هو مؤسس المملكة العربية السعودية؟',
        answer_text_ar: 'الملك عبدالعزيز بن عبدالرحمن آل سعود',
        question_media_url: '',
        answer_media_url: '',
        status: 'active'
      },
    ];
    filename = 'questions_template.xlsx';
  }

  const worksheet = XLSX.utils.json_to_sheet(data);

  const columnWidths = Object.keys(data[0] || {}).map(key => ({
    wch: Math.max(key.length + 5, 20)
  }));
  worksheet['!cols'] = columnWidths;

  const workbook = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(workbook, worksheet, 'Data');
  XLSX.writeFile(workbook, filename);
};

export const exportToExcel = (data: any[], filename: string, sheetName: string = 'Data') => {
  const worksheet = XLSX.utils.json_to_sheet(data);

  const columnWidths = Object.keys(data[0] || {}).map(key => ({
    wch: Math.max(key.length + 5, 20)
  }));
  worksheet['!cols'] = columnWidths;

  const workbook = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(workbook, worksheet, sheetName);
  XLSX.writeFile(workbook, filename);
};
